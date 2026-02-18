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
data "aws_caller_identity" "current" {}

# Uncomment when needed by future modules:
#
# data "aws_region" "current" {}
#
# data "aws_partition" "current" {}
