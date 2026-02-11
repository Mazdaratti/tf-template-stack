# Development Environment - Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "azs" {
  description = "Availability zones used by the network module."
  value       = module.network.azs
}

output "public_subnet_ids" {
  description = "A list of IDs of public subnets (empty if none)"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "A list of IDs of private subnets (empty if none)"
  value       = module.network.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "A list of CIDRs of public subnets (empty if none)"
  value       = module.network.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "A list of CIDRs of private subnets (empty if none)"
  value       = module.network.private_subnet_cidrs
}

output "public_route_table_id" {
  description = "The ID of the public route table if created, otherwise null"
  value       = module.network.public_route_table_id
}

############################################
# AZ name keyed outputs (useful for NAT wiring)
############################################

output "private_route_table_ids_by_az" {
  description = "A map of AZ name =>private route table ID (empty if none)"
  value       = module.network.private_route_table_ids_by_az
}

output "public_subnet_ids_by_az" {
  description = "A map of AZ name =>public subnet ID (empty if none)"
  value       = module.network.public_subnet_ids_by_az
}

output "private_subnet_ids_by_az" {
  description = "A map of AZ name =>private subnet ID (empty if none)"
  value       = module.network.private_subnet_ids_by_az
}

############################################
# NAT Gateway
############################################

output "nat_gateway_ids" {
  description = "Map of NAT key => NAT Gateway ID. Keys are AZ names in per_az mode or 'single' in single mode."
  value       = module.nat_gateway.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Map of NAT key => public IP address of the NAT Gateway."
  value       = module.nat_gateway.nat_gateway_public_ips
}

output "nat_eip_allocation_ids" {
  description = "Map of NAT key => EIP allocation ID used by the NAT Gateway."
  value       = module.nat_gateway.eip_allocation_ids
}

############################################
# Gateway endpoints (S3, DynamoDB)
############################################

output "gateway_endpoints_ids" {
  description = "Map of service name => VPC Endpoint ID for gateway endpoints (S3, DynamoDB)."
  value       = module.vpc_gateway_endpoints.endpoint_ids
}

output "s3_gateway_endpoint_id" {
  description = "VPC Endpoint ID for S3 gateway endpoint (null if disabled)."
  value       = module.vpc_gateway_endpoints.s3_endpoint_id
}

output "dynamodb_gateway_endpoint_id" {
  description = "VPC Endpoint ID for DynamoDB gateway endpoint (null if disabled)."
  value       = module.vpc_gateway_endpoints.dynamodb_endpoint_id
}

############################################
# VPC Interface Endpoints (PrivateLink)
############################################

output "interface_endpoint_ids" {
  description = "Map of service name => VPC Endpoint ID for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.endpoint_ids
}

output "interface_endpoint_arns" {
  description = "Map of service name => VPC Endpoint ARN for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.endpoint_arns
}

output "interface_endpoint_dns_entries" {
  description = "Map of service name => list of DNS entries for interface endpoints (PrivateLink)."
  value       = module.vpc_interface_endpoints.dns_entries
}

output "enabled_interface_endpoint_services" {
  description = "Set of enabled interface endpoint service keys."
  value       = module.vpc_interface_endpoints.enabled_services
}

output "interface_endpoint_security_group_id" {
  description = "Security group ID created by the module (null here because SG is managed externally)."
  value       = module.vpc_interface_endpoints.security_group_id
}