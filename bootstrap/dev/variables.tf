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
  description = "GitHub branch name allowed to assume the role."
  type        = string
  default     = "main"
}

variable "attach_admin_policy" {
  description = "Whether to attach AWS managed AdministratorAccess policy to the GitHub Actions role (broad permissions)."
  type        = bool
  default     = false
}

variable "create_permissions_boundary" {
  description = "If true, create and attach an example permissions boundary to the role. Recommend true as a guardrail example"
  type        = bool
  default     = true
}



