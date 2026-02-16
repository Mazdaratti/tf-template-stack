############################################
# Outputs
#
# Outputs are values other modules/env layers can reuse.
# Example: other modules may need the bucket ARN for IAM policies.
############################################

output "bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_id" {
  description = "The ID of the S3 bucket (same as the bucket name for S3)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name (useful for some integrations)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The regional bucket domain name (recommended for region-specific endpoints)."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region."
  value       = aws_s3_bucket.this.hosted_zone_id
}
