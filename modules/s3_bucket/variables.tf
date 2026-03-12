############################################
# Identity + tagging (consistent pattern)
############################################

variable "project_name" {
  description = "Project name used for naming/tagging."
  type        = string
}

variable "environment" {
  description = "Environment name used for naming/tagging (e.g., dev, staging, prod)."
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

############################################
# Bucket basics
############################################

variable "bucket_name" {
  description = "The S3 bucket name. Must be globally unique."
  type        = string

  # Practical validation (S3 has more edge cases, but this catches common mistakes).
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 chars, start/end with [a-z0-9], and contain only lowercase letters, numbers, dots, and hyphens."
  }
}

variable "force_destroy" {
  description = "If true, Terraform can delete the bucket even if it contains objects. Keep false for production by default."
  type        = bool
  default     = false
}

############################################
# Versioning
############################################

variable "versioning_enabled" {
  description = "Enable S3 versioning."
  type        = bool
  default     = true
}

############################################
# Encryption (secure by default)
############################################

variable "encryption" {
  description = <<-EOT
  Default encryption configuration for the bucket.

  type:
    - "S3"  => SSE-S3 (AES256)
    - "KMS" => SSE-KMS (AWS-managed key by default, or a customer-managed key if kms_key_arn is provided)

  kms_key_arn:
    - Optional. Only used when type == "KMS".
    - Pass a key ARN from the kms_keys module to use a customer-managed key.
  EOT

  type = object({
    type        = string
    kms_key_arn = optional(string)
  })

  default = {
    type        = "S3"
    kms_key_arn = null
  }

  validation {
    condition     = contains(["S3", "KMS"], var.encryption.type)
    error_message = "encryption.type must be either \"S3\" or \"KMS\"."
  }

  validation {
    condition = (
      var.encryption.type != "KMS" ||
      var.encryption.kms_key_arn == null ||
      can(regex("^arn:aws:kms:", var.encryption.kms_key_arn))
    )
    error_message = "If provided, encryption.kms_key_arn must look like a KMS key ARN (arn:aws:kms:...)."
  }
}

############################################
# Access logging (optional)
############################################

variable "access_logging" {
  description = <<-EOT
  Server access logging configuration (optional).

  If enabled = true, you must provide target_bucket.
  target_prefix is optional and helps separate logs by application/team.
  EOT

  type = object({
    enabled       = bool
    target_bucket = optional(string)
    target_prefix = optional(string)
  })

  default = {
    enabled       = false
    target_bucket = null
    target_prefix = null
  }

  validation {
    condition     = var.access_logging.enabled == false || (try(length(var.access_logging.target_bucket), 0) > 0)
    error_message = "When access_logging.enabled is true, access_logging.target_bucket must be set."
  }
}

############################################
# Lifecycle rules (optional)
############################################

variable "lifecycle_rules" {
  description = <<-EOT
  Optional lifecycle rules for the bucket.

  Supported (minimal, production-grade):
  - expiration_days (current objects)
  - noncurrent_version_expiration_days (older versions)
  - abort_incomplete_multipart_upload_days (cleanup)

  Scope (optional):
  - prefix
  - tags
  If neither prefix nor tags are set, the rule applies to the whole bucket.
  EOT

  type = list(object({
    id      = string
    enabled = bool

    prefix = optional(string)
    tags   = optional(map(string))

    expiration_days                        = optional(number)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))

  default = []

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules : (
        try(r.expiration_days > 0, true)
      )
    ])
    error_message = "If set, lifecycle_rules[*].expiration_days must be > 0."
  }

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules : (
        try(r.noncurrent_version_expiration_days > 0, true)
      )
    ])
    error_message = "If set, lifecycle_rules[*].noncurrent_version_expiration_days must be > 0."
  }

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules : (
        try(r.abort_incomplete_multipart_upload_days > 0, true)
      )
    ])
    error_message = "If set, lifecycle_rules[*].abort_incomplete_multipart_upload_days must be > 0."
  }
}

############################################
# Bucket policy (baseline + optional injection)
############################################

variable "attach_deny_insecure_transport_policy" {
  description = "If true, attach a baseline bucket policy that denies any request over insecure transport (non-TLS)."
  type        = bool
  default     = true
}

variable "policy_json" {
  description = "Optional bucket policy JSON to attach (combined with baseline TLS-only policy unless disabled)."
  type        = string
  default     = null
}
