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
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

############################################
# Naming
############################################

variable "log_group_name_prefix" {
  description = <<-EOT
  Prefix used to construct CloudWatch Log Group names.

  The module creates names in the form:
    <log_group_name_prefix>/<name_suffix>

  Recommended env/dev pattern:
    "/<project_name>/<environment>"

  Note: the module will trim a trailing "/" from this value to avoid "//" in names.
  EOT
  type        = string

  validation {
    condition     = length(trimspace(var.log_group_name_prefix)) > 0
    error_message = "log_group_name_prefix must not be empty."
  }
}

############################################
# Retention (baseline + per-log-group override)
############################################

variable "retention_in_days" {
  description = "Default retention period (in days) for log groups, unless overridden per log group."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days > 0
    error_message = "retention_in_days must be greater than 0."
  }
}

############################################
# Encryption (optional; baseline + per-log-group override)
############################################

variable "kms_key_arn" {
  description = <<-EOT
  Optional default KMS key ARN used to encrypt CloudWatch Log Groups.

  Resolution order for each log group:
  1) var.log_groups[KEY].kms_key_arn (per-log-group override)
  2) var.kms_key_arn (module-level default)
  3) null (no KMS encryption)
  EOT
  type        = string
  default     = null

  validation {
    condition = (
      var.kms_key_arn == null ||
      can(regex("^arn:aws(-[a-z]+)?:kms:[a-z0-9-]+:[0-9]{12}:key\\/.+$", var.kms_key_arn))
    )
    error_message = "kms_key_arn must be null or a valid KMS key ARN (arn:aws:kms:region:account-id:key/...)."
  }
}

############################################
# Log groups to create (controlled set)
############################################

variable "log_groups" {
  description = <<-EOT
  Map of CloudWatch Log Groups to create.

  Map key:
    - Stable identifier used in Terraform state and module outputs.
    - Does NOT affect the log group name.

  Value fields:
    - name_suffix (required): appended to the prefix to form the full log group name
    - retention_in_days (optional): override default retention for this log group
    - kms_key_arn (optional): override default KMS key for this log group
  EOT

  type = map(object({
    name_suffix       = string
    retention_in_days = optional(number)
    kms_key_arn       = optional(string)
  }))

  validation {
    condition = alltrue([
      for _, v in var.log_groups : length(trimspace(v.name_suffix)) > 0
    ])
    error_message = "Each log group must have a non-empty name_suffix."
  }

  validation {
    condition = alltrue([
      for _, v in var.log_groups : (
        try(v.retention_in_days > 0, true)
      )
    ])
    error_message = "If provided, each log group's retention_in_days must be greater than 0."
  }

  validation {
    condition = alltrue([
      for _, v in var.log_groups : (
        try(v.kms_key_arn, null) == null ||
        can(regex("^arn:aws(-[a-z]+)?:kms:[a-z0-9-]+:[0-9]{12}:key\\/.+$", v.kms_key_arn))
      )
    ])
    error_message = "If provided, each log group's kms_key_arn must be a valid KMS key ARN."
  }
}
