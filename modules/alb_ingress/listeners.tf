############################################
# Listeners
############################################
#
# This module creates one listener per
# var.listeners entry.
#
# v1 behavior:
# - protocol: HTTP
# - default action: forward to one target group
# - advanced listener rules are intentionally
#   out of scope for this baseline module version
############################################

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)

  default_action {
    type             = lower(each.value.default_action.type)
    target_group_arn = aws_lb_target_group.this[each.value.default_action.target_group_key].arn
  }

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.alb_name}-${each.key}-lsn"
    }
  )
}
