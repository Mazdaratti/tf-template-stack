############################################
# Example: basic_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Internal ALB baseline
# - HTTP listener on port 80
# - One IP target group for future ECS service attachment
# - CIDR-based ingress and default all-egress
# - Access logs disabled
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

############################################
# Minimal network for ALB placement
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alb-ingress-example-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.42.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-example-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.42.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "alb-ingress-example-private-b"
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
  ingress_cidr_ipv4 = ["10.42.0.0/16"]
  egress_cidr_ipv4  = ["0.0.0.0/0"]

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

  ##########################################
  # Access logs
  ##########################################
  access_logs = {
    enabled = false
  }
}
