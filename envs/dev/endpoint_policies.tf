############################################
# Gateway endpoint policy templates (OPTIONAL)
############################################
#
# This file contains EXAMPLES ONLY.
# Nothing in this file is active until you:
#   1) Uncomment the policy documents
#   2) Pass endpoint_policy_json into the
#      vpc_gateway_endpoints module in main.tf
#
# Purpose:
# - Show real-world policy patterns
# - Keep dev environment secure by default
# - Make policies easy to copy to other envs
#

############################################
# Example 1 — Broad (NOT recommended for prod)
############################################
#
# Allows full access to S3/DynamoDB via the
# gateway endpoint. This is equivalent to
# the AWS default endpoint policy.
#
# Use ONLY for quick prototyping.
#

# data "aws_iam_policy_document" "vpce_s3_broad" {
#   statement {
#     effect  = "Allow"
#     actions = ["s3:*"]
#     resources = ["*"]
#   }
# }

############################################
# Example 2 — Restricted to specific S3 bucket
############################################
#
# Recommended pattern.
# In real projects, replace the ARN with:
#   module.storage.bucket_arn
#

# data "aws_iam_policy_document" "vpce_s3_restricted" {
#   statement {
#     effect  = "Allow"
#     actions = ["s3:*"]
#
#     resources = [
#       "arn:aws:s3:::example-bucket",
#       "arn:aws:s3:::example-bucket/*"
#     ]
#   }
# }

############################################
# Example 3 — Restricted DynamoDB table
############################################
#
# Replace the ARN with:
#   module.dynamodb.table_arn
#

# data "aws_iam_policy_document" "vpce_dynamodb_restricted" {
#   statement {
#     effect  = "Allow"
#     actions = ["dynamodb:*"]
#
#     resources = [
#       "arn:aws:dynamodb:eu-central-1:123456789012:table/example-table"
#     ]
#   }
# }

############################################
# How to enable policies
############################################
#
# 1) Uncomment ONE policy per service above
# 2) In envs/dev/main.tf add:
#
# endpoint_policy_json = {
#   s3       = data.aws_iam_policy_document.vpce_s3_restricted.json
#   dynamodb = data.aws_iam_policy_document.vpce_dynamodb_restricted.json
# }
#
# If a service is omitted, AWS default policy is used.
#
