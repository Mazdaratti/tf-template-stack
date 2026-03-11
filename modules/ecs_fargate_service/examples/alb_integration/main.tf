############################################
# Example: alb_integration
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - An internet-facing ALB placed in public subnets
# - A private ECS Fargate service placed in private subnets
# - NAT-backed outbound access for private tasks
# - SG-to-SG least-privilege traffic from ALB to service
# - Service attachment to an existing ALB target group
#
# Why is the ALB internet-facing here?
# - This keeps the example easy to test after apply.
# - Users can reach the ALB from the public Internet on port 80.
#
# Why are ECS tasks still private?
# - This matches the intended service-layer architecture in the repo.
# - Tasks do not receive public IPs and are not directly reachable.
#
# Why does the example create ALB resources directly?
# - Module examples should stay standalone.
# - The example should demonstrate ecs_fargate_service in isolation,
#   without depending on other local modules.
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# Minimal network for ALB + private service
############################################
#
# Network shape in this example:
# - public subnets: ALB + NAT Gateway
# - private subnets: ECS tasks
#
# This is slightly larger than the smallest possible demo,
# but it reflects the real private-service pattern better.
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.81.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-fargate-service-alb-example-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ecs-fargate-service-alb-example-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.81.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-fargate-service-alb-example-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.81.11.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-fargate-service-alb-example-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.81.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-fargate-service-alb-example-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.81.21.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-fargate-service-alb-example-private-b"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "ecs-fargate-service-alb-example-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "ecs-fargate-service-alb-example-nat"
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
    Name = "ecs-fargate-service-alb-example-public"
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
    Name = "ecs-fargate-service-alb-example-private"
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
  name = "ecs-fargate-service-alb-example-cluster"

  tags = {
    Name = "ecs-fargate-service-alb-example-cluster"
  }
}

############################################
# Standalone ALB resources for service attachment
############################################
#
# These resources are created directly in the example so the
# example stays standalone and does not depend on alb_ingress.
#
# The target group uses target_type = "ip" because ECS tasks
# running with awsvpc networking register by IP address.
############################################

resource "aws_security_group" "alb" {
  name        = "ecs-fargate-service-alb-example-alb-sg"
  description = "Example ALB security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "ecs-fargate-service-alb-example-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_anywhere" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"

  description = "Allow HTTP traffic to the example ALB"
}

resource "aws_lb" "this" {
  name               = "ecs-fargate-svc-example"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "ecs-fargate-service-alb-example"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "ecs-fargate-svc-app"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "ecs-fargate-service-alb-example-app"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
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

  # NGINX is reconfigured to listen on port 8080 so the
  # container port matches the ALB target group port.
  container = {
    name  = "app"
    image = "public.ecr.aws/docker/library/nginx:stable"
    port  = 8080
    command = [
      "sh",
      "-c",
      "sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
    ]
  }

  load_balancer = {
    target_group_arn = aws_lb_target_group.app.arn
  }

  # Only the ALB security group is allowed to reach the
  # service, which keeps ingress least-privilege.
  ingress_source_security_group_ids = [aws_security_group.alb.id]

  enable_cloudwatch_logging         = true
  log_retention_in_days             = 7
  health_check_grace_period_seconds = 30
}

resource "aws_vpc_security_group_egress_rule" "alb_to_service" {
  security_group_id            = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = module.ecs_fargate_service.security_group_id

  description = "Allow ALB traffic to the ECS service on port 8080"
}
