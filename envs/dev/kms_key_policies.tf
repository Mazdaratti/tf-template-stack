############################################
# KMS key policies (ACTIVE)
############################################
#
# This file is loaded by Terraform (because it ends with `.tf`).
#
# Add ACTIVE KMS key policy documents here when you need custom policies.
# Then pass the JSON into module "kms_keys" in main.tf per key:
#
# keys = {
#   <key_name> = {
#     ...
#     policy = data.aws_iam_policy_document.<name>.json
#   }
# }
#
# If `policy` is omitted for a key, the kms_keys module applies its safe
# default policy (prevents lockout).
#
# Examples and templates live in:
# - kms_key_policies.tf.example
#
############################################

############################################
# logs key policy (ACTIVE)
#
# Why this custom policy is needed:
# - the kms_keys module default policy is intentionally minimal
# - it prevents account lockout by keeping full access for account root
# - but it does NOT automatically grant usage rights to AWS services
#
# In this dev baseline, the "logs" key is used by:
# - logging_baseline (CloudWatch Log Group for VPC Flow Logs)
# - ecs_fargate_service (module-managed ECS service log group)
#
# CloudWatch Logs must be explicitly allowed to use the key.
# We keep that permission narrow by:
# - granting access only to the regional CloudWatch Logs service principal
# - restricting use through the CloudWatch Logs encryption context
############################################

data "aws_iam_policy_document" "logs_kms" {
  # Keep the default safety property:
  # account root retains full control and the key cannot become orphaned.
  statement {
    sid    = "AllowAccountRootFullAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow CloudWatch Logs in this region to use the key for log-group
  # encryption and decryption operations.
  statement {
    sid    = "AllowCloudWatchLogsUseOfKey"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "logs.${var.aws_region}.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    # Restrict usage to CloudWatch Logs encryption requests in this account/region.
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
      ]
    }
  }
}
