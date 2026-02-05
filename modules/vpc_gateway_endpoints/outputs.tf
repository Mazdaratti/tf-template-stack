output "endpoint_ids" {
  description = "Map of gateway endpoint service => VPC endpoint ID."
  value       = { for svc, ep in aws_vpc_endpoint.gateway : svc => ep.id }
}

output "s3_endpoint_id" {
  description = "VPC endpoint ID for S3 gateway endpoint (null if disabled)."
  value       = try(aws_vpc_endpoint.gateway["s3"].id, null)
}

output "dynamodb_endpoint_id" {
  description = "VPC endpoint ID for DynamoDB gateway endpoint (null if disabled)."
  value       = try(aws_vpc_endpoint.gateway["dynamodb"].id, null)
}

