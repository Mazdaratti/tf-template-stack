provider "aws" {
  region = "eu-central-1"
}

############################################
# Locals (naming + tagging consistency)
############################################

locals {
  project_name = "vpce-interface-platform-baseline"
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
  cidr_block           = "10.91.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-vpc"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, 100 + count.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-private-${data.aws_availability_zones.available.names[count.index]}"
  })
}

############################################
# Shared security group (managed outside module)
############################################

# Real-world pattern:
# - A platform/team often owns security groups centrally.
# - The module only consumes SG IDs.
resource "aws_security_group" "vpce_shared" {
  name        = "${local.project_name}-${local.environment}-endpoint-sg"
  description = "Shared SG for interface endpoints (external to module)"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-endpoint-sg"
  })
}

# Allow HTTPS from within the VPC CIDR (a common baseline).
# This is more realistic than 0.0.0.0/0 and shows hardening.
resource "aws_vpc_security_group_ingress_rule" "vpce_https_from_vpc" {
  security_group_id = aws_security_group.vpce_shared.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  cidr_ipv4   = aws_vpc.this.cidr_block
  description = "Allow HTTPS to interface endpoints from within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "vpce_all_egress" {
  security_group_id = aws_security_group.vpce_shared.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic from interface endpoints"
}

############################################
# Module call: platform baseline endpoints
############################################

module "vpc_interface_endpoints" {
  source = "../../"

  project_name = local.project_name
  environment  = local.environment

  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private : s.id]

  # External SG pattern (module does not create SG)
  create_security_group = false
  security_group_ids    = [aws_security_group.vpce_shared.id]

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
    logs = {
      enabled = true
    }
    secretsmanager = {
      enabled = true
    }
  }

  common_tags = local.common_tags
}
