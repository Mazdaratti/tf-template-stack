provider "aws" {
  region = "eu-central-1"
}

############################################
# Minimal network for NAT demonstration
############################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project_name = "nat-example"
  environment  = "dev"

  # Still create subnets in 2 AZs, but use a single NAT Gateway
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Module      = "nat_gateway-example"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-igw"
  })
}

############################################
# Public subnets
############################################

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, index(local.azs, each.key))
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-public-rt"
  })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

############################################
# Private subnets + private route tables
############################################

resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 100 + index(local.azs, each.key))

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  for_each = toset(local.azs)

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${local.environment}-private-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

############################################
# NAT Gateway module call (single)
############################################

module "nat_gateway" {
  source = "../../"

  project_name = local.project_name
  environment  = local.environment
  common_tags  = local.common_tags

  public_subnet_ids_by_az = {
    for az, s in aws_subnet.public :
    az => s.id
  }

  private_route_table_ids_by_az = {
    for az, rt in aws_route_table.private :
    az => rt.id
  }

  enabled       = true
  mode          = "single"
  create_routes = true
}
