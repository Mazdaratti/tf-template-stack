locals {
  # Standard tags enforced across the repository.
  # The env layer passes project/environment values, and we always mark resources as Terraform-managed.
  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.common_tags
  )

  # Convenience flags so main.tf stays readable for beginners.
  encryption_is_kms = var.encryption.type == "KMS"

  # AWS S3 encryption algorithm values used by the provider resource.
  sse_algorithm = local.encryption_is_kms ? "aws:kms" : "AES256"

  # If KMS is selected and a key ARN is provided, we use it.
  # If it is null, we intentionally omit kms_master_key_id and AWS will use the AWS-managed key for S3 (aws/s3).
  kms_key_arn = local.encryption_is_kms ? try(var.encryption.kms_key_arn, null) : null

  # Access logging is optional.
  logging_enabled = var.access_logging.enabled

  # Bucket policy is optional. We create a policy if:
  # - baseline TLS-only deny is enabled OR
  # - user provided policy_json
  policy_enabled = var.attach_deny_insecure_transport_policy || var.policy_json != null
}
