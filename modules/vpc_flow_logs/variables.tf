############################################
# Identity + tagging (consistent pattern)
############################################

variable "project_name" {
  description = "Project name used for tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name used for tagging (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "common_tags" {
  description = "Additional tags to merge with enforced tags."
  type        = map(string)
  default     = {}
}

############################################
# VPC Flow Logs inputs
############################################

variable "vpc_id" {
  description = "ID of the VPC to enable Flow Logs for."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "log_group_arn" {
  description = "ARN of an existing CloudWatch Log Group to receive VPC Flow Logs (owned outside this module)."
  type        = string

  validation {
    condition     = length(trimspace(var.log_group_arn)) > 0
    error_message = "log_group_arn must not be empty."
  }
}

variable "traffic_type" {
  description = "Traffic type to log. Valid values: ALL, ACCEPT, REJECT."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.traffic_type)
    error_message = "traffic_type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "max_aggregation_interval" {
  description = "Maximum aggregation interval in seconds. Valid values: 60 or 600. If null, AWS default is used."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.vpc_flow_logs_max_aggregation_interval)
    error_message = "vpc_flow_logs_max_aggregation_interval must be one of: 60, 600."
  }
}

############################################
# IAM guardrail (optional)
############################################

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN to attach to the Flow Logs IAM role."
  type        = string
  default     = null
}