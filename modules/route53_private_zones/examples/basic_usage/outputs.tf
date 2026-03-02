############################################
# Outputs
############################################
#
# These outputs help users quickly inspect
# what the module created in this example.
############################################

output "zone_ids" {
  description = "Map of logical zone key => Route53 private hosted zone ID."
  value       = module.route53_private_zones.zone_ids
}

output "zone_names" {
  description = "Map of logical zone key => hosted zone DNS name."
  value       = module.route53_private_zones.zone_names
}

output "record_fqdns" {
  description = "Map of '<zone_key>::<record_key>' => computed record FQDN."
  value       = module.route53_private_zones.record_fqdns
}
