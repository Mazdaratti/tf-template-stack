############################################
# Locals
############################################

locals {

  ##########################################
  # Naming normalization
  ##########################################
  #
  # We trim a trailing "/" so callers can pass either:
  #   "/project/env"
  # or
  #   "/project/env/"
  # without producing "//" in log group names.
  ##########################################
  log_group_name_prefix = trimsuffix(var.log_group_name_prefix, "/")

  ##########################################
  # 1. Enforced tags
  ##########################################
  #
  # These tags are mandatory for all resources in this repository.
  #
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ##########################################
  # 2. Merged tags
  ##########################################
  #
  # Merge user-provided common_tags with enforced tags.
  # merge() order matters:
  # - Later values override earlier ones.
  # - Enforced tags are placed last so they cannot be overridden.
  #
  merged_tags = merge(
    var.common_tags,
    local.enforced_tags
  )
}
