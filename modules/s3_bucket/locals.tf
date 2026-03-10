locals {

  ############################################
  # 1. Enforced tags
  ############################################
  #
  # These tags are mandatory for all resources in this repository.
  # They ensure consistent tagging across all modules.
  #

  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ############################################
  # 2. Merged tags
  ############################################
  #
  # Merge user-provided common_tags with enforced tags.
  #
  # merge() order matters:
  # - Later values override earlier ones.
  #
  # Here:
  #   var.common_tags -> can add additional tags
  #   enforced_tags   -> always present and cannot be overridden
  #

  merged_tags = merge(
    var.common_tags,
    local.enforced_tags
  )

  ############################################
  # 3. Encryption helpers
  ############################################
  #
  # Convenience flags so main.tf stays readable for beginners.
  # This module supports:
  # - SSE-S3 (AES256) [default]
  # - SSE-KMS (aws:kms)
  #

  encryption_is_kms = var.encryption.type == "KMS"

  # AWS S3 encryption algorithm values used by the provider resource.
  sse_algorithm = local.encryption_is_kms ? "aws:kms" : "AES256"

  # If KMS is selected and a key ARN is provided, we use it.
  # If it is null, we intentionally omit kms_master_key_id and AWS will use the AWS-managed key for S3 (aws/s3).
  kms_key_arn = local.encryption_is_kms ? try(var.encryption.kms_key_arn, null) : null

  ############################################
  # 4. Optional feature flags
  ############################################
  #
  # Keep feature toggles here so main.tf stays readable.
  #

  # Access logging is optional.
  logging_enabled = var.access_logging.enabled

  # Bucket policy is optional. We create a policy if:
  # - baseline TLS-only deny is enabled OR
  # - user provided policy_json
  policy_enabled = var.attach_deny_insecure_transport_policy || var.policy_json != null
}
