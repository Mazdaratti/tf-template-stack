############################################
# Outputs
############################################

############################################
# Zone IDs
#
# Map key = var.zones key
# Value   = created Route53 private hosted zone ID
############################################

output "zone_ids" {
  description = "Map of logical zone key => Route53 private hosted zone ID."

  value = {
    for key, zone in aws_route53_zone.this :
    key => zone.zone_id
  }
}

############################################
# Zone names
#
# Map key = var.zones key
# Value   = hosted zone DNS name
############################################

output "zone_names" {
  description = "Map of logical zone key => hosted zone DNS name."

  value = {
    for key, zone in aws_route53_zone.this :
    key => zone.name
  }
}

############################################
# Record FQDNs
#
# Map key = "<zone_key>::<record_key>"
# Value   = computed record FQDN
#
# Returns an empty map when no records are defined.
############################################

output "record_fqdns" {
  description = "Map of '<zone_key>::<record_key>' => computed record FQDN for created records."
  value       = local.record_fqdns
}
