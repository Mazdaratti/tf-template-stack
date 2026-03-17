locals {
  backend_enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  backend_merged_tags = merge(var.common_tags, local.backend_enforced_tags)

  state_bucket_name = var.state_bucket_name != null ? var.state_bucket_name : "${var.project_name}-${var.environment}-tf-state-${random_id.bucket_suffix.hex}"
  lock_table_name   = var.lock_table_name != null ? var.lock_table_name : "${var.project_name}-${var.environment}-tf-lock"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_bucket_name
  force_destroy = true

  tags = merge(local.backend_merged_tags, {
    Name = "Terraform State - ${var.environment}"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.backend_merged_tags, {
    Name = "Terraform State Lock - ${var.environment}"
  })
}
