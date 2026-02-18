############################################
# KMS key policies (ACTIVE)
############################################
#
# This file is loaded by Terraform (because it ends with `.tf`).
#
# Add ACTIVE KMS key policy documents here when you need custom policies.
# Then pass the JSON into module "kms_keys" in main.tf per key:
#
# keys = {
#   <key_name> = {
#     ...
#     policy = data.aws_iam_policy_document.<name>.json
#   }
# }
#
# If `policy` is omitted for a key, the kms_keys module applies its safe
# default policy (prevents lockout).
#
# Examples and templates live in:
# - kms_key_policies.tf.example
#
############################################
