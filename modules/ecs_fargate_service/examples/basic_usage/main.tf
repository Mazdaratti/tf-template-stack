############################################
# Example: basic_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - One ECS cluster for service placement
# - One private-subnet Fargate service
# - Module-managed task roles, security group, and log group
# - No ALB attachment in the minimal baseline
#
# Note:
# This example creates a NAT Gateway so private Fargate
# tasks can pull images and reach required AWS/public
# endpoints without assigning public IPs.
#
# Why are the ECS tasks placed in private subnets?
# - This matches the intended baseline architecture for the module.
# - Tasks do not receive public IPs and are not directly reachable.
#
# Why is a NAT Gateway included?
# - Private Fargate tasks still need outbound connectivity to pull
#   container images and publish logs.
# - Using NAT keeps the service private while still making the
#   example runnable end-to-end.
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# Minimal network for private task placement
############################################
#
# Network shape in this example:
# - public subnets: NAT Gateway placement
# - private subnets: ECS tasks
#
# This is larger than the smallest possible demo, but it reflects
# the private-service pattern more accurately than a public-subnet
# example with assign_public_ip = true.

resource "aws_vpc" "this" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-fargate-service-example-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ecs-fargate-service-example-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.80.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-fargate-service-example-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.80.11.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-fargate-service-example-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.80.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-fargate-service-example-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.80.21.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-fargate-service-example-private-b"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "ecs-fargate-service-example-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "ecs-fargate-service-example-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "ecs-fargate-service-example-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # NAT Gateway is required here so private Fargate tasks
  # can pull container images and publish logs while staying
  # in private subnets with assign_public_ip = false.
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "ecs-fargate-service-example-private"
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

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

############################################
# ECS cluster baseline for service placement
############################################

resource "aws_ecs_cluster" "this" {
  name = "ecs-fargate-service-example-cluster"

  tags = {
    Name = "ecs-fargate-service-example-cluster"
  }
}

module "ecs_fargate_service" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "ecs-fargate-service-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  ##########################################
  # Core wiring
  ##########################################
  cluster_arn = aws_ecs_cluster.this.arn
  vpc_id      = aws_vpc.this.id
  subnet_ids  = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  ##########################################
  # Service baseline
  ##########################################
  desired_count    = 1
  assign_public_ip = false

  cpu    = 256
  memory = 512

  # This example uses a simple public image so the module can be
  # exercised without first creating an ECR repository.
  container = {
    name  = "app"
    image = "public.ecr.aws/docker/library/nginx:stable"
    port  = 80
    environment = {
      NGINX_ENTRYPOINT_QUIET_LOGS = "1"
    }
  }

  enable_cloudwatch_logging = true
  log_retention_in_days     = 7
}
