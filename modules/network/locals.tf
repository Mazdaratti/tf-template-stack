############################################
# Tags (consistent enforced pattern)
############################################

locals {
  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Final tags applied to resources.
  # Enforced tags are placed last so they cannot be overridden.
  merged_tags = merge(var.common_tags, local.enforced_tags)
}

############################################
# Availability Zones (hybrid)
############################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = var.azs != null && length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

############################################
# Subnet counts (hybrid)
############################################

locals {
  public_count = var.create_public_subnets ? (
    var.public_subnet_cidrs != null ? length(var.public_subnet_cidrs) : var.public_subnet_count
  ) : 0

  private_count = var.create_private_subnets ? (
    var.private_subnet_cidrs != null ? length(var.private_subnet_cidrs) : var.private_subnet_count
  ) : 0
}

############################################
# CIDR derivation defaults (when lists are null)
#
# newbits=8 is a practical default for /16 VPCs -> /24 subnets.
# Public:  indices 0.. (public_count-1)
# Private: indices 100.. (100+private_count-1)
############################################

locals {
  subnet_newbits = 8

  public_cidrs_derived = [
    for i in range(local.public_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i)
  ]
  private_cidrs_derived = [
    for i in range(local.private_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, 100 + i)
  ]

  public_cidrs  = var.public_subnet_cidrs != null ? var.public_subnet_cidrs : local.public_cidrs_derived
  private_cidrs = var.private_subnet_cidrs != null ? var.private_subnet_cidrs : local.private_cidrs_derived
}

############################################
# Build stable for_each maps for subnets
############################################

locals {
  public_subnets = {
    for i, cidr in local.public_cidrs :
    format("public-%02d", i) => {
      index      = i
      cidr_block = cidr
      az         = local.azs[i % length(local.azs)]
    }
  }

  private_subnets = {
    for i, cidr in local.private_cidrs :
    format("private-%02d", i) => {
      index      = i
      cidr_block = cidr
      az         = local.azs[i % length(local.azs)]
    }
  }
}

############################################
# Private route tables per AZ (v1)
############################################

locals {
  private_route_tables_by_az = {
    for az in distinct([for _, s in local.private_subnets : s.az]) : az => az
  }
}
