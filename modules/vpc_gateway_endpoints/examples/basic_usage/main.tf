provider "aws" {
  region = "eu-central-1"
}

############################################
# Minimal VPC for gateway endpoint demo
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project     = "gateway-endpoints-example"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Name        = "gateway-endpoints-example-dev-vpc"
  }
}

############################################
# Route table to attach gateway endpoints
############################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Project     = "gateway-endpoints-example"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Name        = "gateway-endpoints-example-dev-private-rt"
  }
}

############################################
# Module call
############################################

module "gateway_endpoints" {
  source = "../../"

  project_name = "gateway-endpoints-example"
  environment  = "dev"

  vpc_id          = aws_vpc.this.id
  route_table_ids = [aws_route_table.private.id]

  gateway_endpoints = {
    s3       = true
    dynamodb = true
  }

  common_tags = {
    Team = "Platform"
  }
}
