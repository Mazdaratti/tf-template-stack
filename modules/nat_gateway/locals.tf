############################################
# Tags (consistent enforced pattern)
############################################

locals {
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Final tags applied to resources
  # User-provided tags can add extra keys, but enforced tags are always present.
  merged_tags = merge(var.common_tags, local.enforced_tags)
}

############################################
# Mode logic / helpers
############################################

locals {
  # Master switch for NAT creationIf module is disabled, create nothing
  nat_enabled = var.enabled

  # Determine which AZs we are targeting based on private route tables
  # Keys are AZ names (eu-central-1a, eu-central-1b, ...)
  target_azs = sort(keys(var.private_route_table_ids_by_az))

  # Mode flags
  ## True if we create a NAT Gateway per AZ (recommended for prod)
  is_per_az = var.mode == "per_az"

  # Keys we use for resource addressing:
  # - per_az mode  => one key per AZ name
  # - single mode  => one key "single"
  # - disabled     => empty list (no resources created)
  nat_keys = local.nat_enabled ? (local.is_per_az ? local.target_azs : ["single"]) : []
}

############################################
# EIP allocation IDs (create vs reuse)
############################################

locals {
  # If reuse_eip_allocation_ids is provided, we do not create aws_eip resources.
  # Instead, NAT Gateways will be created using the provided allocation IDs.
  reuse_eips = var.reuse_eip_allocation_ids != null
}


