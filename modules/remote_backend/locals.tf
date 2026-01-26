locals {
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  merged_tags = merge(var.common_tags, local.enforced_tags)

  state_bucket_name = var.state_bucket_name != null ? var.state_bucket_name : "${var.project_name}-${var.environment}-tf-state-${random_id.bucket_suffix.hex}"
  lock_table_name   = var.lock_table_name != null ? var.lock_table_name : "${var.project_name}-${var.environment}-tf-lock"
}
