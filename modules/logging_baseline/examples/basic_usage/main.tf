############################################
# Example: Basic Usage
#
# This example demonstrates how to:
# - Create multiple shared CloudWatch Log Groups
# - Use default retention (30 days)
# - Use naming prefix based on project/environment
#
# No KMS encryption is configured in this example.
############################################

provider "aws" {
  # Pick any region you normally use for testing.
  region = "eu-central-1"
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
  #
  # Final names will look like:
  #   /example-project/dev/<suffix>
  ##########################################
  log_group_name_prefix = "/example-project/dev"

  ##########################################
  # Default retention
  ##########################################
  retention_in_days = 30

  ##########################################
  # Log groups to create
  ##########################################
  log_groups = {
    vpc_flow_logs = {
      name_suffix = "vpc-flow-logs"
    }

    application_logs = {
      name_suffix       = "app-logs"
      retention_in_days = 14
    }
  }
}