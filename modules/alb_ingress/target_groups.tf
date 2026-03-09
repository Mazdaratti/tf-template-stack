############################################
# Target Groups
############################################
#
# This module creates one target group per
# var.target_groups entry.
#
# Design notes:
# - target_type is restricted to "ip" in v1
#   to align with ECS Fargate service attachment.
# - health check settings are configurable per
#   target group with safe defaults from variables.tf.
############################################

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  # Name is precomputed in locals.tf to ensure
  # AWS naming constraints are satisfied.
  name = local.target_group_names[each.key]

  vpc_id      = var.vpc_id
  port        = each.value.port
  protocol    = upper(each.value.protocol)
  target_type = lower(each.value.target_type)

  deregistration_delay          = try(each.value.deregistration_delay, null)
  slow_start                    = try(each.value.slow_start, null)
  load_balancing_algorithm_type = try(each.value.load_balancing_algorithm_type, null)

  health_check {
    path                = try(each.value.health_check.path, "/")
    protocol            = upper(try(each.value.health_check.protocol, "HTTP"))
    matcher             = try(each.value.health_check.matcher, "200-399")
    interval            = try(each.value.health_check.interval, 30)
    timeout             = try(each.value.health_check.timeout, 5)
    healthy_threshold   = try(each.value.health_check.healthy_threshold, 3)
    unhealthy_threshold = try(each.value.health_check.unhealthy_threshold, 3)
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.target_group_names[each.key]
    }
  )
}
