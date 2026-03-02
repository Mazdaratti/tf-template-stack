############################################
# Locals
############################################

locals {

  ##########################################
  # 1. Enforced tags
  ##########################################
  #
  # These tags are mandatory for all resources in this repository.
  #
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ##########################################
  # 2. Merged tags
  ##########################################
  #
  # Merge enforced tags with user-provided common_tags.
  # merge() order matters:
  # - Later values override earlier ones.
  #
  merged_tags = merge(
    local.enforced_tags,
    var.common_tags
  )

  ##########################################
  # 3. Additional VPC associations (flattened)
  #
  # Route53 private zones require one VPC at
  # creation time (handled in aws_route53_zone).
  # Any extra VPCs are created separately with
  # aws_route53_zone_association.
  #
  # We flatten:
  # zone -> extra associations list -> single map
  # so resources can use for_each deterministically.
  #
  # Key format: "<zone_key>::<original_index>"
  # We use idx + 1 because slice(...) starts from
  # the second original item.
  ##########################################
  extra_vpc_associations = merge([
    for zone_key, zone in var.zones : {
      for idx, assoc in slice(zone.vpc_associations, 1, length(zone.vpc_associations)) :
      "${zone_key}::${idx + 1}" => {
        zone_key   = zone_key
        vpc_id     = assoc.vpc_id
        vpc_region = try(assoc.vpc_region, null)
      }
    }
  ]...)

  ##########################################
  # 4. Records (flattened)
  #
  # Input records are defined per zone:
  # var.zones[zone_key].records[record_key]
  #
  # We flatten everything into one map to allow
  # a single aws_route53_record resource block.
  #
  # Key format: "<zone_key>::<record_key>"
  # "::" avoids ambiguity with DNS-like keys.
  ##########################################
  records_flat = merge([
    for zone_key, zone in var.zones : {
      for record_key, record in coalesce(zone.records, {}) :
      "${zone_key}::${record_key}" => {
        zone_key    = zone_key
        record_key  = record_key
        domain_name = zone.domain_name
        type        = upper(record.type)
        ttl         = coalesce(record.ttl, 300)
        values      = record.values
      }
    }
  ]...)

  ##########################################
  # 5. Computed record FQDNs
  #
  # Record key conventions:
  # - "@" => apex record (zone root)
  # - otherwise => "<record_key>.<domain_name>"
  #
  # Precomputing FQDNs here keeps main.tf clean.
  ##########################################
  record_fqdns = {
    for k, r in local.records_flat :
    k => (
      trimspace(r.record_key) == "@"
      ? r.domain_name
      : "${r.record_key}.${r.domain_name}"
    )
  }
}
