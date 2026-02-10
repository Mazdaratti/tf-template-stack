provider "aws" {
  region = "eu-central-1"
}

############################################
# Locals (naming + tagging consistency)
############################################

locals {
  project_name = "vpce-interface-ssm-minimal"
  environment  = "dev"

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Module      = "vpc_interface_endpoints"
  }
}

############################################
# Minimal VPC + private subnets (standalone)
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.90.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-vpc"
  })

}

data "aws_availability_zones" "available" {
  state = "available"
}

# Two private subnets in two AZs (HA baseline)
resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, 100 + count.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-${data.aws_availability_zones.available.names[count.index]}"
  })
}

############################################
# Interface VPC Endpoints (SSM minimal)
############################################

module "vpc_interface_endpoints" {
  source = "../../"

  project_name = local.project_name
  environment  = local.environment

  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private : s.id]

  # Let the module create a minimal baseline SG.
  create_security_group = true

  interface_endpoints = {
    ssm = {
      enabled = true
    }
    ec2messages = {
      enabled = true
    }
    ssmmessages = {
      enabled = true
    }
  }

  common_tags = local.common_tags
}
