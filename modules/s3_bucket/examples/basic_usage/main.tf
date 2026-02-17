############################################
# Example: basic_usage
#
# This example is self-contained and runnable.
# It demonstrates:
# - Secure-by-default S3 bucket baseline from the module
# - Versioning enabled
# - Lifecycle rules (expire objects, expire noncurrent versions,
#   abort incomplete multipart uploads)
#
# Note: S3 bucket names must be globally unique, so we add a random suffix.
############################################

provider "aws" {
  # Pick any region you normally use for testing.
  region = "eu-central-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "s3_bucket" {
  source = "../../"

  project_name = "tf-template-stack"
  environment  = "example"

  common_tags = {
    Owner = "example"
  }

  bucket_name = "example-secure-bucket-${random_id.suffix.hex}"

  # Secure defaults are enabled by the module:
  # - Block Public Access
  # - BucketOwnerEnforced (no ACLs)
  # - Default encryption (SSE-S3 by default)
  # - TLS-only deny policy enabled by default
  versioning_enabled = true

  ##########################################
  # Lifecycle rules example
  ##########################################
  lifecycle_rules = [
    # 1) Expire objects under "logs/" after 30 days
    {
      id      = "expire-logs"
      enabled = true

      prefix          = "logs/"
      expiration_days = 30
    },

    # 2) Expire older object versions after 30 days
    {
      id      = "expire-noncurrent-versions"
      enabled = true

      noncurrent_version_expiration_days = 30
    },

    # 3) Abort incomplete multipart uploads after 7 days
    {
      id      = "abort-incomplete-multipart"
      enabled = true

      abort_incomplete_multipart_upload_days = 7
    }
  ]
}
