############################################
# Example: public_mode_minimal
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Internet-facing ALB mode (internal = false)
# - Public subnet placement
# - HTTP listener on port 80
# - One IP target group for future service attachment
# - Ingress restricted to explicit CIDR ranges
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

############################################
# Minimal network for public ALB placement
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.62.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alb-ingress-public-example-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "alb-ingress-public-example-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.62.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "alb-ingress-public-example-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.62.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "alb-ingress-public-example-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "alb-ingress-public-example-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
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
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # Internet-facing ALB
  internal = false

  ##########################################
  # Security group ingress/egress
  ##########################################
  # Example CIDR restriction for public mode.
  # Example CIDR restriction using RFC5737 documentation ranges.
  # Replace with real client networks when testing in a real environment.
  ingress_cidr_ipv4 = [
    "203.0.113.0/24",
    "198.51.100.0/24"
  ]
  egress_cidr_ipv4 = ["0.0.0.0/0"]

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
