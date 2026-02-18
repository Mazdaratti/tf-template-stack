# Development Environment - Data Sources
#
# Data sources read information from AWS (no resources created).
# We keep them in one place to avoid repetition across env files as the stack grows.
#
# Typical uses:
# - account_id for globally-unique resource names (e.g., S3 bucket names)
# - region / partition for ARNs and service-specific configuration

data "aws_caller_identity" "current" {}

# Uncomment when needed by future modules:
# data "aws_region" "current" {}
# data "aws_partition" "current" {}