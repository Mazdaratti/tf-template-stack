# =============================================================================
# examples/with_prevent_destroy/main.tf
# Advanced usage example with lifecycle protection (prevent_destroy)
# Suitable for production environments where accidental deletion must be prevented
# =============================================================================

provider "aws" {
  region = "eu-central-1"
}

module "remote_backend" {
  source = "../.."

  project_name = "remote-backend-test"
  environment  = "prod"

  common_tags = {
    Project      = "tf-template-stack"
    ManagedBy    = "Terraform"
    Environment  = "Production"
    Team         = "DevOps"
    Module       = "remote_backend"
    CriticalData = "true"
  }
}
