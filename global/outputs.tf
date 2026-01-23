output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  description = "Available zones in the region"
  value       = data.aws_availability_zones.available.names
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
