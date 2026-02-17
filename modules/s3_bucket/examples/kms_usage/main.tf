############################################
# Example: kms_usage
#
# This example is self-contained and runnable out of the box.
# It demonstrates:
# - Creating a small KMS key for the example
# - Using that key for SSE-KMS encryption in the s3_bucket module
#
# Note: S3 bucket names must be globally unique, so we add a random suffix.
############################################

provider "aws" {
  region = "eu-central-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

############################################
# KMS key used by the S3 bucket encryption
############################################

resource "aws_kms_key" "example" {
  description             = "Example KMS key for s3_bucket kms_usage example"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project     = "tf-template-stack"
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "example" {
  name          = "alias/tf-template-stack-s3-bucket-example-${random_id.suffix.hex}"
  target_key_id = aws_kms_key.example.key_id
}

############################################
# S3 bucket module using SSE-KMS
############################################

module "s3_bucket" {
  source = "../../"

  project_name = "tf-template-stack"
  environment  = "example"

  common_tags = {
    Owner = "example"
  }

  bucket_name = "example-kms-bucket-${random_id.suffix.hex}"

  encryption = {
    type        = "KMS"
    kms_key_arn = aws_kms_key.example.arn
  }

  versioning_enabled = true
}
