############################################
# ECS task IAM
############################################
#
# This module creates two IAM roles:
# - task execution role: used by ECS agent/runtime for image pull,
#   log delivery, and related platform actions
# - task role: assumed by the application container itself
#
# Keeping them separate follows AWS best practice and allows
# least-privilege workload access later without overloading the
# execution role.
############################################

############################################
# IAM policy documents
############################################

##########################################
# 1. ECS tasks assume role policy
##########################################
#
# Both the execution role and task role are assumed
# by the ECS tasks service principal.
#
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid     = "AllowECSTasksService"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

############################################
# Task execution role
############################################
#
# This role uses the AWS-managed baseline policy for:
# - pulling images from ECR
# - publishing container logs
# - reading common task startup metadata supported by ECS
#
# Optional inline policies can be attached for future workload
# needs without changing the baseline role structure.
############################################

resource "aws_iam_role" "task_execution" {
  name               = "${local.service_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  permissions_boundary = var.permissions_boundary_arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.service_name}-task-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "task_execution_inline" {
  for_each = {
    for index, policy_json in var.execution_role_policy_json :
    tostring(index) => policy_json
  }

  name   = "${local.service_name}-task-execution-${each.key}"
  role   = aws_iam_role.task_execution.name
  policy = each.value
}

############################################
# Task role
############################################
#
# The task role intentionally starts with no application
# permissions by default. Callers can attach explicit inline
# policies through task_role_policy_json when the workload
# needs AWS access.
############################################

resource "aws_iam_role" "task" {
  name               = "${local.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  permissions_boundary = var.permissions_boundary_arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.service_name}-task-role"
    }
  )
}

resource "aws_iam_role_policy" "task_inline" {
  for_each = {
    for index, policy_json in var.task_role_policy_json :
    tostring(index) => policy_json
  }

  name   = "${local.service_name}-task-${each.key}"
  role   = aws_iam_role.task.name
  policy = each.value
}
