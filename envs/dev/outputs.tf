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
