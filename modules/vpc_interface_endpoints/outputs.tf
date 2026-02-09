############################################
# Interface endpoints outputs
############################################

output "endpoint_ids" {
  description = "Map of service => interface VPC endpoint ID."
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.id }
}

output "endpoint_arns" {
  description = "Map of service => interface VPC endpoint ARN."
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.arn }
}

output "dns_entries" {
  description = "Map of service => list of DNS entries for the interface endpoint."
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.dns_entry }
}

output "enabled_services" {
  description = "Set of enabled interface endpoint service keys."
  value       = toset(keys(local.enabled_interface_endpoints))
}

############################################
# Security group outputs
############################################

output "security_group_id" {
  description = "Security group ID created by this module (null if not created). Use this to add extra rules from envs/*."
  value       = var.create_security_group ? aws_security_group.endpoint[0].id : null
}
