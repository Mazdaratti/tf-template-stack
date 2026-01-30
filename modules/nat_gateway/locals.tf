############################################
# Tags (consistent enforced pattern)
############################################

locals {
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  merged_tags = merge(var.common_tags, local.enforced_tags)
}

############################################
# Mode logic / sanity helpers
############################################

locals {
  # If module is disabled, create nothing
  nat_enabled = var.enabled

  # Determine which AZs we are targeting based on private route tables
  target_azs = sort(keys(var.private_route_table_ids))

  # Mode flags
  is_per_az = var.mode == "per_az"
  is_single = var.mode == "single"

  # How many NAT gateways we intend to create
  nat_count = local.nat_enabled ? (local.is_per_az ? length(local.target_azs) : 1) : 0
}

############################################
# EIP allocation IDs (create vs reuse)
############################################

locals {
  reuse_eips = var.reuse_eip_allocation_ids != null

  # A small helper for checking: if we reuse EIPs, the count should match nat_count
  reuse_eip_count_ok = !local.reuse_eips || length(var.reuse_eip_allocation_ids) == local.nat_count
}

############################################
# Stable keys for NAT instances
############################################
locals {
  # NAT keys:
  # - per_az: keys are AZ names (e.g., eu-central-1a)
  # - single: key is "single"
  nat_keys = local.nat_enabled ? (local.is_per_az ? local.target_azs : ["single"]) : []

  nat_instance = {
    for k in local.nat_keys : k => {
      key = k
    }
  }
}
