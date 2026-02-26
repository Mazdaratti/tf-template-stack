############################################
# Example: basic_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Creating a minimal VPC
# - Creating a CloudWatch Log Group (destination)
# - Enabling VPC Flow Logs to CloudWatch Logs using the module
#
# Note:
# In the main repository environments, the CloudWatch Log Group is owned
# by the logging_baseline module. This example creates it only to make the
# example runnable.
############################################

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-flow-logs-example"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/example/vpc-flow-logs"
  retention_in_days = 7

  tags = {
    Name = "vpc-flow-logs-example"
  }
}

module "vpc_flow_logs" {
  source = "../../"

  project_name = "vpc-flow-logs-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  vpc_id        = aws_vpc.this.id
  log_group_arn = aws_cloudwatch_log_group.vpc_flow_logs.arn

  # Optional arguments (shown with defaults)
  #
  # traffic_type             = "ALL"  # Default: "ALL"
  # max_aggregation_interval = 600    # Default: 600
  # permissions_boundary_arn = null   # Optional IAM permissions boundary
}