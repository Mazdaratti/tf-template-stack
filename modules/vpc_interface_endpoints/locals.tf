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

############################################
# Service name construction
############################################

locals {
  # Interface endpoint service name is region-specific.
  # Example:
  #   com.amazonaws.eu-central-1.ssm
  #
  # We derive region from the AWS provider to avoid passing it manually.
  service_names = {
    for svc, _ in local.enabled_interface_endpoints :
    svc => "com.amazonaws.${data.aws_region.current.region}.${svc}"
  }
}