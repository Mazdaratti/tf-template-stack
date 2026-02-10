############################################
# Example outputs
############################################

output "vpc_id" {
  description = "VPC ID used by the example."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used to place interface endpoints."
  value       = [for s in aws_subnet.private : s.id]
}

output "endpoint_ids" {
  description = "Map of service => interface endpoint ID."
  value       = module.vpc_interface_endpoints.endpoint_ids
}

output "dns_entries" {
  description = "Map of service => DNS entries for the interface endpoints."
  value       = module.vpc_interface_endpoints.dns_entries
}

output "security_group_id" {
  description = "Security group ID created by the module (because create_security_group=true in this example)."
  value       = module.vpc_interface_endpoints.security_group_id
}

output "enabled_services" {
  description = "Set of enabled interface endpoint service keys."
  value       = module.vpc_interface_endpoints.enabled_services
}