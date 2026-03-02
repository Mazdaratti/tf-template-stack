############################################
# Private hosted zones + associations + records
############################################
#
# Design:
# - One private zone per var.zones entry.
# - First VPC association is embedded directly in aws_route53_zone
#   because private zone creation requires at least one VPC.
# - Additional VPC associations are managed separately with
#   aws_route53_zone_association using flattened locals.
# - Optional DNS records are managed with one aws_route53_record
#   resource driven by flattened locals.
############################################

############################################
# 1) Private hosted zones
############################################

resource "aws_route53_zone" "this" {
  for_each = var.zones

  # DNS zone name (e.g., dev.internal)
  name = each.value.domain_name

  # Optional zone metadata / lifecycle behavior
  comment       = try(each.value.comment, null)
  force_destroy = try(each.value.force_destroy, false)

  # Private zones must be associated with a VPC at creation time.
  # We use the first association from input.
  vpc {
    vpc_id     = each.value.vpc_associations[0].vpc_id
    vpc_region = try(each.value.vpc_associations[0].vpc_region, null)
  }

  # Standard repository tags + optional per-zone tags.
  tags = merge(
    local.merged_tags,
    try(each.value.zone_tags, {}),
    {
      Name = "${var.project_name}-${var.environment}-${each.key}-private-zone"
    }
  )
}

############################################
# 2) Additional VPC associations
############################################
#
# Any association beyond the first one is created
# using aws_route53_zone_association.
############################################

resource "aws_route53_zone_association" "extra" {
  for_each = local.extra_vpc_associations

  zone_id = aws_route53_zone.this[each.value.zone_key].zone_id
  vpc_id  = each.value.vpc_id

  # Optional for cross-region association cases.
  vpc_region = each.value.vpc_region
}

############################################
# 3) Optional baseline records
############################################
#
# Supported record types are validated in variables.tf:
# A, AAAA, CNAME, TXT
############################################

resource "aws_route53_record" "this" {
  for_each = local.records_flat

  zone_id = aws_route53_zone.this[each.value.zone_key].zone_id

  # Name is precomputed in locals:
  # - "@" => zone apex
  # - otherwise "<record_key>.<domain_name>"
  name = local.record_fqdns[each.key]

  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.values
}
