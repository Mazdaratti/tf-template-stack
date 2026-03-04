############################################
# ECS Cluster
############################################
#
# This module creates one ECS cluster and optional
# cluster-level settings:
# - Container Insights
# - Capacity providers + default strategy
# - ECS Exec configuration (optional)
#
# It intentionally does NOT create services, tasks,
# ALB, or networking resources.
############################################

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  ##########################################
  # Container Insights
  ##########################################
  #
  # Enables CloudWatch-backed ECS observability
  # at the cluster level.
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  ##########################################
  # Optional ECS Exec configuration
  ##########################################
  #
  # Create cluster configuration only when
  # exec_enabled=true.
  dynamic "configuration" {
    for_each = var.exec_enabled ? [1] : []

    content {
      execute_command_configuration {
        logging = var.exec_logging

        # CloudWatch override is valid only when
        # exec_logging = "OVERRIDE".
        dynamic "log_configuration" {
          for_each = var.exec_logging == "OVERRIDE" ? [1] : []

          content {
            cloud_watch_log_group_name = var.exec_cloudwatch_log_group_name
          }
        }
      }
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.cluster_name
    }
  )
}

############################################
# Capacity providers
############################################
#
# Associates capacity providers with the cluster
# and (optionally) sets a default strategy that
# future services can inherit.
############################################

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = tolist(var.capacity_providers)

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy == null ? [] : var.default_capacity_provider_strategy

    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = try(default_capacity_provider_strategy.value.base, null)
    }
  }
}
