############################################
# Outputs
#
# Outputs make it easy to see what was created after `terraform apply`.
############################################

output "bucket_name" {
  description = "Created bucket name."
  value       = module.s3_bucket.bucket_name
}

output "bucket_arn" {
  description = "Created bucket ARN."
  value       = module.s3_bucket.bucket_arn
}
