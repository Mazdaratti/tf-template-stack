############################################
# ECS task definition
############################################
#
# v1 creates one Fargate task definition with:
# - one typed application container
# - module-managed execution/task roles
# - awsvpc networking
# - optional CloudWatch log configuration
############################################

resource "aws_ecs_task_definition" "this" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([local.container_definition])

  runtime_platform {
    operating_system_family = local.runtime_platform.operating_system_family
    cpu_architecture        = local.runtime_platform.cpu_architecture
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_gib == null ? [] : [var.ephemeral_storage_gib]

    content {
      size_in_gib = ephemeral_storage.value
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.service_name
    }
  )
}

############################################
# ECS service
############################################
#
# This service deploys the single task definition into
# private subnets and optionally attaches it to an
# existing ALB target group.
#
# v1 intentionally keeps deployment behavior simple:
# - Fargate launch type
# - awsvpc networking
# - optional single target group attachment
############################################

resource "aws_ecs_service" "this" {
  name            = local.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  platform_version                   = var.platform_version
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  propagate_tags                     = var.propagate_tags
  health_check_grace_period_seconds  = local.load_balancer_enabled ? var.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = local.load_balancer_enabled ? [var.load_balancer] : []

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = local.container_name
      container_port   = local.load_balancer_container_port
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.service_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.task_execution_managed
  ]
}
