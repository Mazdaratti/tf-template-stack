############################################
# VPC Flow Logs IAM
############################################
#
# IAM role and policy for VPC Flow Logs to publish to CloudWatch Logs.
# This module does NOT create the destination Log Group.
# The destination Log Group and its KMS encryption (if any) are owned elsewhere.
#
# Tagging:
# - Uses the repository standard tagging pattern from locals.tf
# - Adds resource-specific Name tags per resource
############################################

############################################
# IAM Policy Documents
############################################

##########################################
# 1. Assume Role Policy
##########################################
#
# Trust policy allowing the VPC Flow Logs service to assume this role.
#
# Confused deputy protection:
# - aws:SourceAccount
# - aws:SourceArn
#
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowVPCFlowLogsService"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
      ]
    }
  }
}

##########################################
# 2. CloudWatch Logs Delivery Policy
##########################################
#
# Minimal permissions required for VPC Flow Logs delivery to CloudWatch Logs.
# The destination Log Group is provided as an input (var.log_group_arn).
#
data "aws_iam_policy_document" "flow_logs_to_cwl" {

  statement {
    sid    = "AllowWriteToLogGroup"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      var.log_group_arn,
      "${var.log_group_arn}:*"
    ]
  }

  statement {
    sid    = "AllowDescribeLogGroups"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups"
    ]

    # Required for the service to verify the Log Group existence.
    resources = ["*"]
  }
}

############################################
# IAM Role
############################################

resource "aws_iam_role" "this" {
  name               = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  permissions_boundary = var.permissions_boundary_arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
    }
  )
}

############################################
# Inline Role Policy
############################################

resource "aws_iam_role_policy" "this" {
  name   = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.flow_logs_to_cwl.json
}