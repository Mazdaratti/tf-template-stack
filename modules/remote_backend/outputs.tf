output "state_bucket_name" {
  description = "The name of the S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "The ARN of the S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "The name of the DynamoDB table for state locking."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "lock_table_arn" {
  description = "The ARN of the DynamoDB table for state locking."
  value       = aws_dynamodb_table.terraform_lock.arn
}
