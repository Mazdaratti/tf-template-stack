# =============================================================================
# examples/basic_usage/main.tf
# Minimal working example of the remote_backend module
# for a persistent non-dev environment
# =============================================================================

provider "aws" {
  region = "eu-central-1"
}

module "remote_backend" {
  source = "../.."

  project_name = "remote-backend-test"
  environment  = "stage"

  common_tags = {
    Project     = "tf-template-stack"
    ManagedBy   = "Terraform"
    Environment = "Staging"
    Team        = "DevOps"
    Module      = "remote_backend"
  }
}
