############################################
# VPC Flow Logs
############################################
#
# Enables VPC Flow Logs for a given VPC and publishes to an existing
# CloudWatch Log Group (provided via var.log_group_arn).
#
# This module does NOT create the destination Log Group.
############################################

resource "aws_flow_log" "this" {
  vpc_id = var.vpc_id

  traffic_type = var.traffic_type

  log_destination_type = "cloud-watch-logs"
  log_destination      = var.log_group_arn
  iam_role_arn         = aws_iam_role.this.arn

  max_aggregation_interval = var.max_aggregation_interval

  tags = merge(
    local.merged_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
    }
  )
}