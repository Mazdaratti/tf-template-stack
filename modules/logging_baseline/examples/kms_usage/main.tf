############################################
# Example: kms_usage
#
# This example demonstrates:
# - Creating shared CloudWatch Log Groups
# - Enabling KMS encryption (module-level default)
# - Overriding KMS encryption per log group (optional)
#
# Note:
# For simplicity, this example creates KMS keys inline.
# In the main repository, KMS keys are created by the kms_keys module
# and passed into logging_baseline via outputs.
############################################

provider "aws" {
  # Pick any region you normally use for testing.
  region = "eu-central-1"
}

############################################
# Example KMS keys (for demonstration only)
############################################

resource "aws_kms_key" "logs_default" {
  description             = "Example KMS key for CloudWatch Logs (module default)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "logs_override" {
  description             = "Example KMS key for CloudWatch Logs (per-log-group override)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "logging_baseline" {
  source = "../../"

  ##########################################
  # Identity (used for tagging)
  ##########################################
  project_name = "example-project"
  environment  = "dev"

  ##########################################
  # Naming
  ##########################################
  log_group_name_prefix = "/example-project/env"

  ##########################################
  # Default retention
  ##########################################
  retention_in_days = 30

  ##########################################
  # Default encryption key (module-level default)
  ##########################################
  kms_key_arn = aws_kms_key.logs_default.arn

  ##########################################
  # Log groups to create
  ##########################################
  log_groups = {
    "vpc_flow_logs" = {
      name_suffix = "vpc-flow-logs"
      # Uses module-level kms_key_arn
    }

    audit_logs = {
      name_suffix = "audit-logs"
      #Demonstrates per-log-group override
      kms_key_arn = aws_kms_key.logs_override.arn
    }
  }
}