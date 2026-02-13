############################################
# KMS key policy templates (OPTIONAL)
############################################
#
# This file contains EXAMPLES ONLY.
# Nothing in this file is active until you:
#   1) Uncomment the policy documents
#   2) Pass policy JSON into the kms_keys module in main.tf
#
# Purpose:
# - Show safe real-world policy patterns
# - Keep dev environment secure by default
# - Make policies easy to copy to other envs
#
# Notes:
# - KMS key policies are security-critical.
# - Misconfiguration can lock you out of a key.
# - Always keep an admin statement for your account/root
#   (or a dedicated KMS admin role).
#

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

############################################
# Example 1 — Safe admin baseline (recommended)
############################################
#
# Keeps full control in the account (prevents lockout).
# Suitable as the "admin statement" in any custom policy.
#

# data "aws_iam_policy_document" "kms_admin_baseline" {
#   statement {
#     sid    = "AllowAccountRootFullAccess"
#     effect = "Allow"
#
#     principals {
#       type        = "AWS"
#       identifiers = [
#         "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
#       ]
#     }
#
#     actions   = ["kms:*"]
#     resources = ["*"]
#   }
# }

############################################
# Example 2 — Admin baseline + delegate usage to role
############################################
#
# Template showing a common pattern:
# - Admin: account root has full access
# - Usage: allow a specific IAM role to encrypt/decrypt
#
# In real projects, replace the role ARN with something like:
#   module.iam.role_arn
#

# data "aws_iam_policy_document" "kms_delegate_usage_to_role" {
#   statement {
#     sid    = "AllowAccountRootFullAccess"
#     effect = "Allow"
#
#     principals {
#       type        = "AWS"
#       identifiers = [
#         "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
#       ]
#     }
#
#     actions   = ["kms:*"]
#     resources = ["*"]
#   }
#
#   statement {
#     sid    = "AllowKeyUsageForRole"
#     effect = "Allow"
#
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::123456789012:role/example-role"]
#     }
#
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:GenerateDataKey",
#       "kms:DescribeKey"
#     ]
#
#     resources = ["*"]
#   }
# }

############################################
# How to enable a custom policy for a key
############################################
#
# In envs/dev/main.tf (module "kms_keys") set:
#
# keys = {
#   logs = {
#     description = "KMS key for logs"
#     policy      = data.aws_iam_policy_document.kms_delegate_usage_to_role.json
#   }
# }
#
# If policy is omitted, module default policy is used.
#
