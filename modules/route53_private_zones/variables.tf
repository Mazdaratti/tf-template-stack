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
# Private hosted zones + optional records
############################################

variable "zones" {
  description = <<-EOT
  Map of private hosted zones to create.

  Map key:
    - Stable logical key used in Terraform state and outputs.

  Value fields:
    - domain_name: DNS zone name (e.g., dev.internal)
    - comment: optional hosted zone comment
    - force_destroy: whether to allow deleting non-empty zones
    - vpc_associations: list of VPCs to associate (at least one required)
    - records: optional map of simple records (A, AAAA, CNAME, TXT)
    - zone_tags: optional per-zone tag additions/overrides
  EOT

  type = map(object({
    domain_name = string

    comment       = optional(string)
    force_destroy = optional(bool, false)

    vpc_associations = list(object({
      vpc_id     = string
      vpc_region = optional(string)
    }))

    records = optional(map(object({
      type   = string
      ttl    = optional(number, 300)
      values = list(string)
    })), {})

    zone_tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for _, z in var.zones : (
        length(trimspace(z.domain_name)) > 0 &&
        length(z.vpc_associations) >= 1 &&
        alltrue([
          for a in z.vpc_associations : length(trimspace(a.vpc_id)) > 0
        ])
      )
    ])
    error_message = "Each zone must have a non-empty domain_name and at least one vpc_association with non-empty vpc_id."
  }

  validation {
    condition = alltrue([
      for _, z in var.zones : alltrue([
        for record_key, _ in coalesce(z.records, {}) : trimspace(record_key) == "@" || length(trimspace(record_key)) > 0
      ])
    ])
    error_message = "Record keys must be non-empty. Use '@' for apex records."
  }

  validation {
    condition = alltrue([
      for _, z in var.zones : alltrue([
        for _, r in coalesce(z.records, {}) : contains(["A", "AAAA", "CNAME", "TXT"], upper(r.type))
      ])
    ])
    error_message = "Record type must be one of: A, AAAA, CNAME, TXT."
  }

  validation {
    condition = alltrue([
      for _, z in var.zones : alltrue([
        for _, r in coalesce(z.records, {}) : coalesce(r.ttl, 300) > 0
      ])
    ])
    error_message = "Record TTL must be greater than 0."
  }

  validation {
    condition = alltrue([
      for _, z in var.zones : alltrue([
        for _, r in coalesce(z.records, {}) : length(r.values) > 0
      ])
    ])
    error_message = "Each record must include at least one value."
  }

  validation {
    condition = alltrue([
      for _, z in var.zones : alltrue([
        for _, r in coalesce(z.records, {}) : (
          upper(r.type) != "CNAME" || length(r.values) == 1
        )
      ])
    ])
    error_message = "CNAME records must contain exactly one value."
  }
}
