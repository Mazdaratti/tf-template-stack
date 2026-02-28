############################################
# Locals
############################################

locals {

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
  # Merge enforced tags with user-provided common_tags.
  # merge() order matters:
  # - Later values override earlier ones.
  #
  merged_tags = merge(
    local.enforced_tags,
    var.common_tags
  )
}