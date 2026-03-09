############################################
# Example: source_sg_ingress
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Internal ALB baseline
# - HTTP listener on port 80
# - One IP target group for future ECS service attachment
# - Ingress controlled by source security group IDs
#   (no CIDR-based ingress rules)
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

############################################
# Minimal network for ALB placement
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.72.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alb-ingress-sg-example-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.72.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-sg-example-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.72.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-sg-example-private-b"
  }
}

############################################
# Source security group (simulated client tier)
############################################
#
# This SG represents workloads that are allowed
# to reach the ALB listener port.
############################################

resource "aws_security_group" "client_tier" {
  name        = "alb-ingress-sg-example-client"
  description = "Example source security group allowed to reach the ALB"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "alb-ingress-sg-example-client"
  }
}

module "alb_ingress" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "alb-ingress-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  ##########################################
  # Core wiring
  ##########################################
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Internal ALB baseline
  internal = true

  ##########################################
  # Security group ingress/egress
  ##########################################
  # SG-based ingress only (no ingress CIDRs).
  ingress_source_security_group_ids = [aws_security_group.client_tier.id]
  egress_cidr_ipv4                  = ["0.0.0.0/0"]

  ##########################################
  # Listener and target group baseline
  ##########################################
  target_groups = {
    app = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "app"
      }
    }
  }

  access_logs = {
    enabled = false
  }
}
