############################################
# Tags (consistent enforced pattern)
############################################

locals {
  # Enforced tags: always applied, cannot be overridden
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Final tags applied to resources
  merged_tags = merge(var.common_tags, local.enforced_tags)
}

############################################
# Enabled endpoints (filtering helper))
############################################

locals {
  # Keep only endpoints explicitly enabled by the caller.
  #
  # This lets the module accept a large map of potential endpoints
  # while creating only those marked enabled = true.
  enabled_interface_endpoints = {
    for svc, cfg in var.interface_endpoints :
    svc => cfg
    if cfg.enabled
  }
}