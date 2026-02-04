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
# Region + enabled services
############################################

locals {
  # Region used to build service names (falls back to provider region)  
  effective_region = coalesce(var.region, data.aws_region.current.region)

  # Enabled gateway endpoints based on flags
  enabled_services = toset(compact([var.gateway_endpoints.s3 ? "s3" : null]))
}