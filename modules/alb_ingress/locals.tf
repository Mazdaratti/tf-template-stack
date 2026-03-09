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
  # Merge user-provided common_tags with enforced tags.
  # merge() order matters:
  # - Later values override earlier ones.
  # - Enforced tags are placed last so they cannot be overridden.
  #
  merged_tags = merge(
    var.common_tags,
    local.enforced_tags
  )

  ##########################################
  # 3. Effective ALB name
  ##########################################
  #
  # If name is explicitly provided, use it.
  # Otherwise derive a consistent default name.
  #
  alb_name = coalesce(
    var.name,
    "${var.project_name}-${var.environment}-alb"
  )

  ##########################################
  # 4. Listener ports (deduplicated)
  ##########################################
  #
  # Security group ingress rules should open
  # exactly the ports used by listeners.
  #
  listener_ports = toset([
    for _, listener in var.listeners : listener.port
  ])
}
