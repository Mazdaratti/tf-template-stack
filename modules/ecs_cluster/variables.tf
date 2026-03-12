############################################
# Identity + tagging
############################################

variable "project_name" {
  description = "Project name used for tagging and naming."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name used for tagging and naming (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "common_tags" {
  description = "Common tags applied to all resources. Enforced tags are merged in the module."
  type        = map(string)
  default     = {}
}

############################################
# Cluster naming
############################################

variable "cluster_name" {
  description = <<-EOT
  Optional ECS cluster name.

  If null, the module uses:
    "<project_name>-<environment>-ecs-cluster"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.cluster_name == null || length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must be null or a non-empty string."
  }
}

############################################
# Observability
############################################

variable "enable_container_insights" {
  description = "Whether to enable ECS Container Insights at the cluster level."
  type        = bool
  default     = true
}

############################################
# Capacity providers (for future service modules)
############################################

variable "capacity_providers" {
  description = <<-EOT
  Set of capacity providers to associate with the cluster.

  Recommended baseline:
    ["FARGATE", "FARGATE_SPOT"]
  EOT
  type        = set(string)
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = length(var.capacity_providers) > 0
    error_message = "capacity_providers must contain at least one item."
  }
}

variable "default_capacity_provider_strategy" {
  description = <<-EOT
  Optional default capacity provider strategy applied at the cluster level.

  Each object:
    - capacity_provider (string, required)
    - weight (number, required, >= 0)
    - base (number, optional, >= 0)

  Rules:
    - capacity_provider must exist in var.capacity_providers
    - list must be non-empty when set (non-null)
  EOT

  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))

  default = null

  validation {
    condition = (
      var.default_capacity_provider_strategy == null ||
      try(length(var.default_capacity_provider_strategy) > 0, true)
    )
    error_message = "default_capacity_provider_strategy must be null or a non-empty list."
  }

  validation {
    condition = (
      var.default_capacity_provider_strategy == null ||
      try(alltrue([
        for s in var.default_capacity_provider_strategy :
        length(trimspace(s.capacity_provider)) > 0
      ]), true)
    )
    error_message = "Each strategy.capacity_provider must be a non-empty string."
  }

  validation {
    condition = (
      var.default_capacity_provider_strategy == null ||
      try(alltrue([for s in var.default_capacity_provider_strategy : s.weight >= 0]), true)
    )
    error_message = "Each strategy.weight must be >= 0."
  }

  validation {
    condition = (
      var.default_capacity_provider_strategy == null ||
      try(alltrue([
        for s in var.default_capacity_provider_strategy :
        s.base == null || s.base >= 0
      ]), true)
    )
    error_message = "If provided, each strategy.base must be >= 0."
  }
}

############################################
# ECS Exec (cluster-level)
############################################

variable "exec_enabled" {
  description = "Whether to enable ECS Exec configuration at the cluster level."
  type        = bool
  default     = false
}

variable "exec_logging" {
  description = <<-EOT
  ECS Exec logging mode.

  Allowed values:
    - DEFAULT
    - OVERRIDE (requires exec_cloudwatch_log_group_name)
    - NONE
  EOT
  type        = string
  default     = "DEFAULT"

  validation {
    condition     = contains(["DEFAULT", "OVERRIDE", "NONE"], var.exec_logging)
    error_message = "exec_logging must be one of: DEFAULT, OVERRIDE, NONE."
  }
}

variable "exec_cloudwatch_log_group_name" {
  description = <<-EOT
  CloudWatch Log Group name used for ECS Exec logs when exec_logging = "OVERRIDE".

  Required only when:
    exec_enabled = true AND exec_logging = "OVERRIDE"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.exec_cloudwatch_log_group_name == null ? true : length(trimspace(var.exec_cloudwatch_log_group_name)) > 0
    error_message = "exec_cloudwatch_log_group_name must be null or a non-empty string."
  }
}
