variable "project_name" {
  description = "Project name used for tagging and default naming."
  type        = string
}

variable "environment" {
  description = "Environment name used for tagging and default naming (e.g., dev, stage, prod)."
  type        = string
}

variable "common_tags" {
  description = "Additional tags to merge with enforced tags."
  type        = map(string)
  default     = {}
}

variable "alias_prefix" {
  description = "Optional prefix for KMS aliases. If null, defaults to '${project_name}-${environment}'."
  type        = string
  default     = null
}

variable "keys" {
  description = <<EOT
Map of KMS keys to create.

Each key object supports:
- description (optional)
- enable_key_rotation (optional, default true)
- deletion_window_in_days (optional, default 30; valid range 7..30)
- policy (optional JSON string; if null, module default policy is used)
- is_enabled (optional, default true)
- multi_region (optional, default false)
- alias_name (optional; full alias name like 'alias/my-key')
- tags (optional; per-key tags merged with module tags)
EOT

  type = map(object({
    description             = optional(string)
    enable_key_rotation     = optional(bool, true)
    deletion_window_in_days = optional(number, 30)
    policy                  = optional(string)
    is_enabled              = optional(bool, true)
    multi_region            = optional(bool, false)
    alias_name              = optional(string)
    tags                    = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for _, v in var.keys :
      v.deletion_window_in_days >= 7 && v.deletion_window_in_days <= 30
    ])
    error_message = "Each key must have deletion_window_in_days between 7 and 30."
  }

  validation {
    condition = alltrue([
      for _, v in var.keys :
      v.alias_name == null || startswith(v.alias_name, "alias/")
    ])
    error_message = "If provided, alias_name must start with 'alias/'."
  }
}
