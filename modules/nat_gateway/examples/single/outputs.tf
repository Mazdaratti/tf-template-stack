output "nat_gateway_ids" {
  description = "Map of AZ name => NAT Gateway ID created by the example"
  value       = module.nat_gateway.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Map of AZ name => public IP address of the NAT Gateways"
  value       = module.nat_gateway.nat_gateway_public_ips
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by AZ name."
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by AZ name."
  value       = { for az, s in aws_subnet.private : az => s.id }
}
