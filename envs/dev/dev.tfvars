############################################
# Dev environment tracked baseline
#
# This file is intentionally committed because it contains
# only non-secret desired-state inputs for envs/dev.
#
# It is the shared source of truth for:
# - local Terraform runs
# - GitHub Actions deployment workflow
############################################

# ---- Core ----
project_name = "tf-template-stack"
environment  = "dev"

# Region used by providers.tf
aws_region = "eu-central-1"

# Tags passed into modules. Modules will enforce:
# Project, Environment, ManagedBy="Terraform"
# and merge these common_tags with enforced tags.
common_tags = {
  Team = "Platform"
}

############################################
# ECS Fargate Service (dev workload)
############################################

# Container image URI for the dev ECS service.
#
# This tracked baseline uses a simple official NGINX image
# so the first GitHub Actions deployment workflow can validate
# ECS + ALB behavior without application-specific complexity.
ecs_service_image_uri = "nginx:stable-alpine"

# ---- Network (VPC) ----
vpc_cidr = "10.10.0.0/16"

# DNS defaults (module defaults: true)
# enable_dns_support   = true
# enable_dns_hostnames = true

############################################
# AZ selection (HYBRID)
############################################

# Default behavior:
# - If azs is NOT set, the module takes the first az_count AZs available in the region.
az_count = 2

# Optional: explicit AZ list (overrides az_count)
# azs = ["eu-central-1a", "eu-central-1b"]

############################################
# Subnet creation toggles
############################################

create_public_subnets  = true
create_private_subnets = true

# Public subnet behavior
map_public_ip_on_launch = true

############################################
# Subnet configuration (HYBRID)
############################################

# Default behavior:
# - If explicit CIDR lists are NOT set, subnets are derived automatically from vpc_cidr.
# - Counts control how many subnets are created.
public_subnet_count  = 2
private_subnet_count = 2

# Optional: explicit subnet CIDRs (full control)
#
# public_subnet_cidrs = [
#   "10.10.10.0/24",
#   "10.10.11.0/24"
# ]
#
# private_subnet_cidrs = [
#   "10.10.110.0/24",
#   "10.10.111.0/24"
# ]

############################################
# NAT Gateway
############################################

enable_nat_gateway = true

# NAT mode:
# - "single" (cheaper dev)
# - "per_az" (recommended for prod)
nat_gateway_mode = "single"

# Whether to create default routes in private route tables pointing to NAT
nat_create_routes = true

# Optional: reuse existing EIP allocation IDs
nat_reuse_eip_allocation_ids = null
