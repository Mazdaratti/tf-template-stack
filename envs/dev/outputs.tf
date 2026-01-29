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
  value       = module.network.public_subnets_ids
}

output "private_subnet_ids" {
  description = "A list of IDs of private subnets (empty if none)"
  value       = module.network.private_subnets_ids
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

output "private_route_table_ids" {
  description = "A map of AZ name =>private route table ID (empty if none)"
  value       = module.network.private_route_table_ids
}


