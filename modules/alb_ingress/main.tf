############################################
# Application Load Balancer
############################################
#
# This module creates one ALB as the shared ingress
# layer for future service modules.
#
# Scope:
# - ALB resource only
# - access logs block (optional)
# - no listeners/target groups in this file
# - no security group rules in this file
############################################

resource "aws_lb" "this" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = var.internal
  subnets            = var.subnet_ids

  # Security group is created in security_group.tf.
  security_groups = [aws_security_group.alb.id]

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields

  # Access logging is optional and controlled by var.access_logs.
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []

    content {
      bucket  = var.access_logs.bucket
      prefix  = try(var.access_logs.prefix, null)
      enabled = true
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.alb_name
    }
  )
}
