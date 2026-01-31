output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "A list of IDs of public subnets (empty if none)"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "A list of IDs of private subnets (empty if none)"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnet_cidrs" {
  description = "A list of CIDRs of public subnets (empty if none)"
  value       = [for s in aws_subnet.public : s.cidr_block]
}

output "private_subnet_cidrs" {
  description = "A list of CIDRs of private subnets (empty if none)"
  value       = [for s in aws_subnet.private : s.cidr_block]
}

output "internet_gateway_id" {
  description = "The ID of the internet gateway if created, otherwise null"
  value       = local.public_count > 0 ? aws_internet_gateway.this[0].id : null
}

output "public_route_table_id" {
  description = "The ID of the public route table if created, otherwise null"
  value       = local.public_count > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "A map of AZ name =>private route table ID (empty if none)"
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}

############################################
# AZ ID keyed outputs (stable across accounts)
############################################

output "public_subnet_ids_by_az_id" {
  description = "Map of AZ ID => public subnet ID (stable across AWS accounts)."
  value       = { for _, s in aws_subnet.public : s.availability_zone_id => s.id }
}

output "private_subnet_ids_by_az_id" {
  description = "Map of AZ ID => private subnet ID (stable across AWS accounts)."
  value       = { for _, s in aws_subnet.private : s.availability_zone_id => s.id }
}

output "public_subnet_cidrs_by_az_id" {
  description = "Map of AZ ID => public subnet CIDR (stable across AWS accounts)."
  value       = { for _, s in aws_subnet.public : s.availability_zone_id => s.cidr_block }

}

output "private_subnet_cidrs_by_az_id" {
  description = "Map of AZ ID => private subnet CIDR (stable across AWS accounts)."
  value       = { for _, s in aws_subnet.private : s.availability_zone_id => s.cidr_block }
}
