############################################
# Example: basic_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Creating one ECS cluster
# - Enabling Container Insights (default behavior)
# - Attaching baseline capacity providers (default behavior)
#
# Note:
# This example creates only cluster-level resources.
# It does not create ECS services or tasks.
############################################

provider "aws" {
  # Keep region explicit so example behavior is predictable.
  region = "eu-central-1"
}

module "ecs_cluster" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "ecs-cluster-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  ##########################################
  # Cluster-level baseline behavior
  ##########################################

  # Enabled by default; included explicitly for clarity in the example.
  enable_container_insights = true

  # Capacity providers default to ["FARGATE", "FARGATE_SPOT"].
  # Omit to keep the example minimal.
}
