variable "aws_region" {
  description = "AWS region where bootstrap resources will be created."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name used for naming/tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stage/prod). Used for naming and for writing env backend.tf."
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "state_bucket_name" {
  description = "Optional override for the Terraform state S3 bucket name."
  type        = string
  default     = null
}

variable "lock_table_name" {
  description = "Optional override for the Terraform lock DynamoDB table name."
  type        = string
  default     = null
}


