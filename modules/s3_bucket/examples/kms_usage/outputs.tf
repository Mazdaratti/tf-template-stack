############################################
# Outputs
#
# These values are printed after apply so you can quickly verify:
# - the bucket was created
# - the module outputs work as expected
############################################

output "bucket_name" {
  description = "Created bucket name."
  value       = module.s3_bucket.bucket_name
}

output "bucket_arn" {
  description = "Created bucket ARN."
  value       = module.s3_bucket.bucket_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for bucket encryption in this example."
  value       = aws_kms_key.example.arn
}
