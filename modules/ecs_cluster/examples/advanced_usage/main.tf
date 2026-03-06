############################################
# Example: advanced_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates optional module features:
# - Explicit, custom capacity provider strategy
# - ECS Exec enabled with log group override
#
# Keep this pattern for non-baseline behavior after cluster module
# is in place and service modules are ready to use exec/spot choices.
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
  project_name = "tf-template-stack"
  environment  = "dev"

  common_tags = {
    Team        = "platform"
    Environment = "dev"
  }

  ##########################################
  # Cluster-level behavior
  ##########################################

  # Container insights remains enabled, as in baseline.
  enable_container_insights = true

  # Explicitly show the baseline provider set.
  # You can use the same values as defaults, but this is helpful
  # when environments need to pin provider choices.
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # Custom default strategy: prefer FARGATE, keep a small SPOT weight.
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

  # ECS Exec override mode is a non-baseline extension. Keep it explicit
  # for environments that need interactive execute-command workflows.
  exec_enabled                  = true
  exec_logging                  = "OVERRIDE"
  exec_cloudwatch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
}
