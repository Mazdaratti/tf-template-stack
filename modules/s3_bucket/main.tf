############################################
# Core S3 bucket (the container)
############################################

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.merged_tags
}

############################################
# Security baseline: block public access
# (always on, secure-by-default)
############################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

############################################
# Security baseline: object ownership
# BucketOwnerEnforced disables ACLs and makes the bucket owner the object owner.
############################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

############################################
# Optional: versioning toggle
############################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

############################################
# Encryption by default (SSE-S3 or SSE-KMS)
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = local.kms_key_arn
    }
  }
}

############################################
# Optional: access logging
############################################

resource "aws_s3_bucket_logging" "this" {
  count = local.logging_enabled ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_logging.target_bucket
  target_prefix = var.access_logging.target_prefix
}

############################################
# Optional: bucket policy
# - baseline TLS-only deny policy (recommended)
# - optional user policy_json injection
############################################

data "aws_iam_policy_document" "this" {
  # If the user provides a policy JSON, we use it as a starting point and then add the baseline statement.
  # If policy_json is null, Terraform treats it as "not set" (no source policy).
  source_policy_documents = var.policy_json != null ? [var.policy_json] : []

  dynamic "statement" {
    for_each = var.attach_deny_insecure_transport_policy ? [1] : []

    content {
      sid    = "DenyInsecureTransport"
      effect = "Deny"

      actions = ["s3:*"]
      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*",
      ]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = 1

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  # This avoids occasional AWS ordering/race issues where policy application happens
  # before ownership/public access settings are in place.
  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this,
  ]
}
