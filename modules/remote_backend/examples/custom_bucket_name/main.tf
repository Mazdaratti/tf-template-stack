# =============================================================================
# examples/custom_bucket_name/main.tf
# Production-oriented usage example
# Suitable for longer-lived environments with explicit naming and tagging
# =============================================================================

provider "aws" {
  region = "eu-central-1"
}

module "remote_backend" {
  source = "../.."

  project_name      = "remote-backend-test"
  environment       = "prod"
  state_bucket_name = "remote-backend-test-prod-tf-state-example"

  common_tags = {
    Project      = "tf-template-stack"
    ManagedBy    = "Terraform"
    Environment  = "Production"
    Team         = "DevOps"
    Module       = "remote_backend"
    CriticalData = "true"
  }
}
