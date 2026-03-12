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

variable "github_org" {
  description = "GitHub organization/user name that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch name allowed to assume the GitHub Actions deploy role."
  type        = string
  default     = "main"
}

variable "attach_admin_policy" {
  description = "Legacy prototyping-only escape hatch. If true, attach AWS managed AdministratorAccess to the GitHub Actions role. Keep disabled for the hardened deployment model."
  type        = bool
  default     = false
}

variable "create_permissions_boundary" {
  description = "If true, create and attach the repo-aligned permissions boundary to the GitHub Actions role."
  type        = bool
  default     = true
}



