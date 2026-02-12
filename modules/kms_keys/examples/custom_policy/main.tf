############################################
# Example: custom policy override
############################################
#
# This example demonstrates how to override the default key policy
# for ONE key by providing `policy = data.aws_iam_policy_document.<name>.json`.
#
# Important:
# - KMS key policies are easy to misconfigure.
# - A broken policy can lock you out of the key.
# - Always keep an "admin" statement that allows your account
#   (or a dedicated admin role) to manage the key.
#

provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

############################################
# Custom policy example
############################################
#
# This policy:
# 1) Allows the account root full admin access (prevents lockout)
# 2) Demonstrates how you could add a "usage" statement for a role
#
# The "usage role" ARN below is an example placeholder.
# In real projects you would reference a real role, e.g.:
#   module.iam_role.role_arn
#

data "aws_iam_policy_document" "kms_custom_example" {
  # Admin statement (recommended)
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

  # Usage statement (template / example)
  #
  # Uncomment and replace the role ARN if you want to test.
  #
  # statement {
  #   sid    = "AllowKeyUsageForRole"
  #   effect = "Allow"
  #
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::123456789012:role/example-role"]
  #   }
  #
  #   actions = [
  #     "kms:Encrypt",
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey",
  #     "kms:DescribeKey"
  #   ]
  #
  #   resources = ["*"]
  # }
}

module "kms_keys" {
  source = "../../"

  # Required (module identity + tagging)
  project_name = "kms-keys-example"
  environment  = "dev"

  ##########################################
  # This time we override policy for one key
  ##########################################

  # Optional (default: {})
  common_tags = {
    Team = "Platform"
  }

  # Optional (default: null -> "<project_name>-<environment>")
  # alias_prefix = "my-custom-prefix"

  ##########################################
  # Keys (map)
  ##########################################
  #
  # Each map entry becomes one KMS key.
  # Below we show ALL optional per-key arguments,
  # commented with their DEFAULT values.
  #

  keys = {
    logs = {
      # Optional (default: null)
      description = "KMS key for log encryption"

      # Optional (default: true)
      enable_key_rotation = true

      # Optional (default: 30; valid range 7..30)
      # deletion_window_in_days = 30

      # Optional (default: true)
      # is_enabled = true

      # Optional (default: false)
      # multi_region = false

      # Optional (default: null -> module safe default policy)
      # Here we show OVERRIDE with a custom policy JSON:
      policy = data.aws_iam_policy_document.kms_custom_example.json

      # Optional (default: {}), per-key extra tags
      tags = {
        Purpose = "logs"
      }

      # Optional (default: null -> alias/<prefix>-<key_name>)
      # alias_name = "alias/my-explicit-alias"
    }

    s3 = {
      # Optional (default: null)
      description = "KMS key for S3 bucket encryption"

      # Optional (default: true)
      enable_key_rotation = true

      # Optional (default: 30; valid range 7..30)
      # deletion_window_in_days = 30

      # Optional (default: true)
      # is_enabled = true

      # Optional (default: false)
      # multi_region = false

      # Optional (default: null -> module safe default policy)
      # policy = null

      # Optional (default: {})
      # tags = {}

      # Optional (default: null -> alias/<prefix>-<key_name>)
      # alias_name = null
    }
  }
}
