############################################
# Example outputs
############################################

output "endpoint_ids" {
  description = "Map of service => interface endpoint ID."
  value       = module.vpc_interface_endpoints.endpoint_ids
}

output "dns_entries" {
  description = "Map of service => DNS entries for the interface endpoints."
  value       = module.vpc_interface_endpoints.dns_entries
}

output "enabled_services" {
  description = "Set of enabled interface endpoint service keys."
  value       = module.vpc_interface_endpoints.enabled_services
}

output "security_group_id" {
  description = "Security group ID created by the module (null here because SG is managed externally)."
  value       = module.vpc_interface_endpoints.security_group_id
}
