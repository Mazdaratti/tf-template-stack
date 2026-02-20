############################################
# Endpoint policies (ACTIVE)
############################################
#
# This file is loaded by Terraform (because it ends with `.tf`).
#
# Add ACTIVE endpoint policy documents here and wire them in `main.tf`
# using `endpoint_policy_json` for:
# - module "vpc_gateway_endpoints"
# - module "vpc_interface_endpoints"
#
# If you do not define or attach policies, AWS default endpoint policies apply.
#
# Examples and templates live in:
# - endpoint_policies.tf.example
#
############################################
# Gateway endpoint policies (ACTIVE)
############################################
#
# S3 gateway endpoint policy restricted to the buckets created in this env.
#
# Why:
# - Endpoint policies apply at the VPC endpoint and limit what traffic can reach S3.
# - This policy keeps S3 access possible, but only for the intended buckets.
#
# Default behavior (if not set):
# - AWS applies the default endpoint policy (effectively broad access).
############################################

data "aws_iam_policy_document" "vpce_s3_restricted_to_env_buckets" {
  statement {
    sid    = "AllowS3OnlyToEnvBuckets"
    effect = "Allow"

    # Minimal-risk approach: allow all S3 actions, but only for selected buckets.
    actions = ["s3:*"]

    resources = [
      module.s3_bucket_logs.bucket_arn,
      "${module.s3_bucket_logs.bucket_arn}/*",
      module.s3_bucket_app.bucket_arn,
      "${module.s3_bucket_app.bucket_arn}/*",
    ]
  }
}

