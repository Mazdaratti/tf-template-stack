# =============================================================================
# examples/basic_usage/main.tf
# Minimal working example of the remote_backend module
# =============================================================================

provider "aws" {
  region = "eu-central-1"
}

module "remote_backend" {
  source = "../.."

  project_name = "remote-backend-test"
  environment  = "dev"

  common_tags = {
    Project     = "tf-template-stack"
    ManagedBy   = "Terraform"
    Environment = "Testing"
    Team        = "DevOps"
    Module      = "remote_backend"
  }
}
