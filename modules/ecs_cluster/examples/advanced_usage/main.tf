############################################
# Example: advanced_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates optional advanced cluster settings:
# - Explicit capacity provider strategy
# - ECS Exec enabled with CloudWatch log override
#
# This is intentionally non-baseline. It is useful when
# you need to validate operational options before wiring
# service layers (ecs_fargate_service/alb_ingress).
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

############################################
# Optional supporting resource for ECS Exec
############################################
resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/aws/ecs/ecs-cluster-example/dev/exec"
  retention_in_days = 30

  tags = {
    Name        = "ecs-cluster-advanced-exec"
    Project     = "ecs-cluster-example"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "ecs_cluster" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "ecs-cluster-example"
  environment  = "dev"

  common_tags = {
    Team = "platform"
  }

  ##########################################
  # Cluster-level behavior
  ##########################################

  # Keep explicit here to demonstrate the control point
  # beyond baseline defaults.
  enable_container_insights = true

  # Capacity providers are supported for later service composition.
  # Using explicit values here shows how to pin them per use case.
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # Custom default strategy for mixed Fargate/Fargate Spot use.
  # It shows a strong preference for FARGATE with fallback to Spot.
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 90
      base              = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 10
    }
  ]

  # In real environments, this log group is usually sourced from
  # a shared logging module/output rather than created inline.
  # ECS Exec is optional and non-baseline:
  # OVERRIDE requires an explicit log group name.
  exec_enabled                    = true
  exec_logging                    = "OVERRIDE"
  exec_cloudwatch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
}
