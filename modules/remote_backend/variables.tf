variable "project_name" {
  description = "Name of the project. Used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod). Used in resource naming."
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "state_bucket_name" {
  description = "Override for the S3 bucket name. If not provided, derived from project_name and environment."
  type        = string
  default     = null
}
