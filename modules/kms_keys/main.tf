############################################
# Data sources
############################################
#
# We use AWS data sources to avoid hardcoding:
# - Account IDs
# - Partitions (aws, aws-cn, aws-us-gov)
#
# This makes the module reusable in any AWS partition/account.
#

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

############################################
# Default KMS key policy (safe baseline)
############################################
#
# If the user does NOT provide a custom policy for a key,
# we apply this default policy.
#
# Why this policy?
# - It prevents "lockout" (the most common KMS mistake),
#   because the account root principal always retains full access.
# - It is generic (not coupled to any service like S3/Logs/etc.).
#
# NOTE:
# - In production, you may want to add additional statements that
#   delegate usage/admin permissions to specific roles.
# - This module supports that via the per-key `policy` override.
#

data "aws_iam_policy_document" "default" {
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
}

############################################
# KMS keys
############################################
#
# We create multiple keys using for_each.
# - Each entry in local.keys_normalized becomes one KMS key.
#
# If var.keys is empty {}:
# - local.keys_normalized is empty
# - no resources are created
#

resource "aws_kms_key" "this" {
  for_each = local.keys_normalized

  description             = each.value.description
  enable_key_rotation     = each.value.enable_key_rotation
  deletion_window_in_days = each.value.deletion_window_in_days
  is_enabled              = each.value.is_enabled
  multi_region            = each.value.multi_region

  ##########################################
  # Key policy selection
  ##########################################
  #
  # If the user provided a custom policy -> use it.
  # Otherwise -> use module default policy.
  #

  policy = each.value.policy != null ? each.value.policy : data.aws_iam_policy_document.default.json

  ##########################################
  # Tags
  ##########################################
  #
  # Tag merge order:
  # 1) enforced + common tags (local.merged_tags)
  # 2) per-key tags (each.value.tags)
  # 3) Name tag (standardized, consistent)
  #

  tags = merge(
    local.merged_tags,
    each.value.tags,
    {
      Name = "${var.project_name}-${var.environment}-kms-${each.key}"
    }
  )
}

############################################
# KMS aliases
############################################
#
# Each key gets exactly one alias.
# Aliases make keys easier to reference in AWS services and IaC.
#
# The alias name is either:
# - user-provided (alias_name), or
# - auto-generated: alias/<prefix>-<key_name>
#

resource "aws_kms_alias" "this" {
  for_each = local.keys_normalized

  name          = each.value.effective_alias_name
  target_key_id = aws_kms_key.this[each.key].key_id
}
