############################################
# Example: basic usage
############################################
#
# This example shows the simplest way to use the kms_keys module:
# - Create 2 KMS keys (logs, s3)
# - Let the module generate safe default key policies
# - Let the module generate aliases automatically
#
# Run from this folder:
#   terraform init
#   terraform plan
#   terraform apply
#

provider "aws" {
  # Keep examples consistent with the repo (same region used elsewhere).
  region = "eu-central-1"
}

module "kms_keys" {
  # In examples we reference the module root with "../../"
  source = "../../"

  # Identity + tags (standard in this repo)
  project_name = "kms-keys-example"
  environment  = "dev"

  common_tags = {
    Team = "Platform"
  }

  ##########################################
  # Keys to create (map-based)
  ##########################################
  #
  # Each map entry becomes one KMS key.
  # Key name ("logs", "s3") is used for:
  # - Output map keys
  # - Default alias name (alias/<prefix>-<key_name>)
  #

  keys = {
    logs = {
      description         = "KMS key for log encryption"
      enable_key_rotation = true
    }

    s3 = {
      description         = "KMS key for S3 bucket encryption"
      enable_key_rotation = true
    }
  }
}
