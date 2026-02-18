############################################
# Development Environment - Data Sources
#
# Data sources read information from AWS.
# They DO NOT create resources.
#
# We centralize shared identity/region/partition
# lookups here to:
# - avoid repetition
# - keep main.tf focused on module wiring
# - support future modules consistently
############################################

# Current AWS account identity
# Used for:
# - globally unique resource naming (e.g., S3 buckets)
# - restricting policies by SourceAccount
#
# @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

# Uncomment when needed by future modules:
#
# @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
# data "aws_region" "current" {}
#
# Current AWS partition (aws, aws-cn, aws-us-gov)
# Used for:
# - restricting policies by Partition
#
# @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition
# data "aws_partition" "current" {}
