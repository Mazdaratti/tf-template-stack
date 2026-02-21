/**
 * -----------------------------------------------------------------------------
 * Module: logging_baseline
 *
 * This file defines the required Terraform and provider versions.
 *
 * We intentionally keep provider requirements consistent across all modules
 * in this repository to ensure predictable behavior and avoid subtle
 * provider-related breaking changes.
 *
 * Terraform >= 1.6.0
 * AWS Provider >= 6.0.0
 * -----------------------------------------------------------------------------
 */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}