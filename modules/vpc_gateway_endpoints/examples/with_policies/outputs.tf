############################################
# Example outputs
############################################

output "vpc_id" {
  description = "ID of the example VPC."
  value       = aws_vpc.this.id
}

output "route_table_id" {
  description = "Private route table used by gateway endpoints."
  value       = aws_route_table.private.id
}

output "s3_bucket_name" {
  description = "Example S3 bucket referenced by endpoint policy."
  value       = aws_s3_bucket.example.bucket
}

output "dynamodb_table_name" {
  description = "Example DynamoDB table referenced by endpoint policy."
  value       = aws_dynamodb_table.example.name
}

output "gateway_endpoint_ids" {
  description = "Gateway endpoint IDs created by the module."
  value       = module.vpc_gateway_endpoints.endpoint_ids
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID (null if disabled)."
  value       = module.vpc_gateway_endpoints.s3_endpoint_id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB gateway endpoint ID (null if disabled)."
  value       = module.vpc_gateway_endpoints.dynamodb_endpoint_id
}
