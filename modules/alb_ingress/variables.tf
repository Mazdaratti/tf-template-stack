############################################
# Identity + tagging
############################################

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name used for naming and tagging (e.g., dev, stage, prod)."
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
# Core wiring
############################################

variable "vpc_id" {
  description = "ID of the VPC where ALB and security group resources are created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs where the ALB will be attached. At least two subnets in different Availability Zones are recommended."
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) >= 2 &&
      alltrue([for subnet_id in var.subnet_ids : length(trimspace(subnet_id)) > 0])
    )
    error_message = "subnet_ids must include at least 2 non-empty subnet IDs for ALB high availability."
  }
}

############################################
# ALB settings
############################################

variable "name" {
  description = <<-EOT
  Optional ALB name.

  If null, the module uses:
    "<project_name>-<environment>-alb"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.name == null || length(trimspace(var.name)) > 0
    error_message = "name must be null or a non-empty string."
  }
}

variable "internal" {
  description = "Whether the ALB is internal. If false, ALB is internet-facing."
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "idle_timeout must be between 1 and 4000 seconds."
  }
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled on the ALB."
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Whether the ALB should drop invalid HTTP header fields."
  type        = bool
  default     = true
}

############################################
# Access logs (optional)
############################################

variable "access_logs" {
  description = <<-EOT
  Optional ALB access logging configuration.

  - enabled: when true, ALB access logs are delivered to S3
  - bucket: destination S3 bucket name (required when enabled=true)
  - prefix: optional object key prefix
  EOT

  type = object({
    enabled = bool
    bucket  = optional(string)
    prefix  = optional(string)
  })

  default = {
    enabled = false
  }

  validation {
    condition = (
      var.access_logs.enabled == false ||
      (
        try(var.access_logs.bucket, null) != null &&
        length(trimspace(var.access_logs.bucket)) > 0
      )
    )
    error_message = "access_logs.bucket must be provided when access_logs.enabled is true."
  }
}

############################################
# Security group ingress/egress model
############################################

variable "ingress_cidr_ipv4" {
  description = "List of IPv4 CIDRs allowed to reach ALB listener ports."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ingress_cidr_ipv4 :
      can(cidrhost(cidr, 0))
    ])
    error_message = "Each value in ingress_cidr_ipv4 must be a valid IPv4 CIDR block."
  }
}

variable "ingress_source_security_group_ids" {
  description = "List of source security group IDs allowed to reach ALB listener ports."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for sg_id in var.ingress_source_security_group_ids :
      length(trimspace(sg_id)) > 0
    ])
    error_message = "ingress_source_security_group_ids must not contain empty values."
  }
}

variable "egress_cidr_ipv4" {
  description = "List of IPv4 CIDRs allowed for ALB outbound traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.egress_cidr_ipv4 :
      can(cidrhost(cidr, 0))
    ])
    error_message = "Each value in egress_cidr_ipv4 must be a valid IPv4 CIDR block."
  }
}

############################################
# Listener / target group configuration
############################################

variable "target_groups" {
  description = <<-EOT
  Map of target groups to create.

  Map key:
    - Stable logical key used by listeners and outputs.

  Value fields:
    - port, protocol, target_type
    - optional health_check
    - optional target group tuning knobs
  EOT

  type = map(object({
    port        = number
    protocol    = string
    target_type = string

    health_check = optional(object({
      path                = optional(string, "/")
      protocol            = optional(string, "HTTP")
      matcher             = optional(string, "200-399")
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }), {})

    deregistration_delay          = optional(number)
    slow_start                    = optional(number)
    load_balancing_algorithm_type = optional(string)
  }))

  validation {
    condition     = length(var.target_groups) > 0
    error_message = "target_groups must include at least one target group."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      tg.port >= 1 && tg.port <= 65535
    ])
    error_message = "Each target group port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      upper(tg.protocol) == "HTTP"
    ])
    error_message = "Each target group protocol must be HTTP in v1."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      lower(tg.target_type) == "ip"
    ])
    error_message = "Each target group target_type must be ip in v1."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      try(tg.deregistration_delay, null) == null || (tg.deregistration_delay >= 0 && tg.deregistration_delay <= 3600)
    ])
    error_message = "If provided, deregistration_delay must be between 0 and 3600."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      try(tg.slow_start, null) == null || (tg.slow_start >= 0 && tg.slow_start <= 900)
    ])
    error_message = "If provided, slow_start must be between 0 and 900."
  }

  validation {
    condition = alltrue([
      for _, tg in var.target_groups :
      try(tg.load_balancing_algorithm_type, null) == null || contains(["round_robin", "least_outstanding_requests"], lower(tg.load_balancing_algorithm_type))
    ])
    error_message = "If provided, load_balancing_algorithm_type must be round_robin or least_outstanding_requests."
  }
}

variable "listeners" {
  description = <<-EOT
  Map of listeners to create.

  Map key:
    - Stable logical key used in Terraform state and outputs.

  Value fields:
    - port, protocol
    - default_action.type
    - default_action.target_group_key (must reference var.target_groups key)
  EOT

  type = map(object({
    port     = number
    protocol = string

    default_action = object({
      type             = string
      target_group_key = string
    })
  }))

  validation {
    condition     = length(var.listeners) > 0
    error_message = "listeners must include at least one listener."
  }

  validation {
    condition = alltrue([
      for _, l in var.listeners :
      l.port >= 1 && l.port <= 65535
    ])
    error_message = "Each listener port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for _, l in var.listeners :
      upper(l.protocol) == "HTTP"
    ])
    error_message = "Each listener protocol must be HTTP in v1."
  }

  validation {
    condition = alltrue([
      for _, l in var.listeners :
      lower(l.default_action.type) == "forward"
    ])
    error_message = "Each listener default_action.type must be forward in v1."
  }
}
