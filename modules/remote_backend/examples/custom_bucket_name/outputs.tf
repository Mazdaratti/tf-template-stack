output "tf_state_bucket_name" {
  value       = module.remote_backend.tf_state_bucket_name
  description = "The name of the S3 bucket used for Terraform state"
}

output "tf_state_bucket_arn" {
  value       = module.remote_backend.tf_state_bucket_arn
  description = "The ARN of the S3 bucket used for Terraform state"
}
