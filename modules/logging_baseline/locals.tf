############################################
# Locals
############################################

locals {
  ##########################################
  # Naming normalization
  #
  # We trim a trailing "/" so callers can pass either:
  #   "/project/env"
  # or
  #   "/project/env/"
  # without producing "//" in log group names.
  ##########################################
  log_group_name_prefix = trimsuffix(var.log_group_name_prefix, "/")

  ##########################################
  # Standard tags (repo-wide convention)
  ##########################################
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
}