output "vpc_id" {
  description = "VPC ID created for the example."
  value       = aws_vpc.this.id
}

output "route_table_id" {
  description = "Route table ID the gateway endpoints are attached to."
  value       = aws_route_table.private.id
}

output "endpoint_ids" {
  description = "Gateway endpoint IDs created by the module."
  value       = module.gateway_endpoints.endpoint_ids
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID (null if disabled)."
  value       = module.gateway_endpoints.s3_endpoint_id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB gateway endpoint ID (null if disabled)."
  value       = module.gateway_endpoints.dynamodb_endpoint_id
}
