############################################
# VPC
############################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

############################################
# Internet Gateway (only if public subnets exist)
############################################

resource "aws_internet_gateway" "this" {
  count = local.public_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

############################################
# Public subnets
############################################

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Tier = "public"
  })
}

############################################
# Private subnets
############################################

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Tier = "private"
  })
}

############################################
# Public route table + route (only if public subnets exist)
############################################

resource "aws_route_table" "public" {
  count = local.public_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-rt-public"
    Tier = "public"
  })
}

resource "aws_route" "public_internet_access" {
  count = local.public_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

############################################
# Private route tables per AZ (no NAT routes in v1)
############################################

resource "aws_route_table" "private" {
  for_each = local.private_route_tables_by_az
  vpc_id   = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-${var.environment}-rt-private-${each.key}"
    Tier = "private"
    AZ   = each.key
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}