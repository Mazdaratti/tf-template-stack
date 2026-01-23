# VPC Module - Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = null # TODO: Update with actual VPC resource
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = []
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = []
}
