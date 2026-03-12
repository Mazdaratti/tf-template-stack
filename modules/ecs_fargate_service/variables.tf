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

variable "cluster_arn" {
  description = "ARN of the existing ECS cluster where the service will run."
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_arn)) > 0
    error_message = "cluster_arn must not be empty."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where service security group resources are created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs where the ECS service tasks will be placed."
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) > 0 &&
      alltrue([for subnet_id in var.subnet_ids : length(trimspace(subnet_id)) > 0])
    )
    error_message = "subnet_ids must include at least one non-empty subnet ID."
  }
}

############################################
# Service naming
############################################

variable "name" {
  description = <<-EOT
  Optional ECS service name.

  If null, the module uses:
    "<project_name>-<environment>-ecs-service"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.name == null || length(trimspace(coalesce(var.name, ""))) > 0
    error_message = "name must be null or a non-empty string."
  }
}

############################################
# ECS service settings
############################################

variable "desired_count" {
  description = "Number of task instances to run for the ECS service."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be greater than or equal to 0."
  }
}

variable "assign_public_ip" {
  description = "Whether tasks receive public IPs. Recommended baseline is false for private subnet deployment."
  type        = bool
  default     = false
}

variable "platform_version" {
  description = "Fargate platform version for the ECS service."
  type        = string
  default     = "LATEST"

  validation {
    condition     = length(trimspace(var.platform_version)) > 0
    error_message = "platform_version must not be empty."
  }
}

variable "health_check_grace_period_seconds" {
  description = <<-EOT
  Optional ECS service health check grace period in seconds.

  This should be set only when the service is attached to a load balancer.
  EOT
  type        = number
  default     = null

  validation {
    condition = (
      var.health_check_grace_period_seconds == null ||
      var.health_check_grace_period_seconds >= 0
    )
    error_message = "health_check_grace_period_seconds must be null or greater than or equal to 0."
  }
}

variable "propagate_tags" {
  description = "Whether ECS should propagate tags from the SERVICE or TASK_DEFINITION."
  type        = string
  default     = "SERVICE"

  validation {
    condition     = contains(["SERVICE", "TASK_DEFINITION"], var.propagate_tags)
    error_message = "propagate_tags must be one of: SERVICE, TASK_DEFINITION."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks during a deployment, as a percentage of desired_count."
  type        = number
  default     = 100

  validation {
    condition = (
      var.deployment_minimum_healthy_percent >= 0 &&
      var.deployment_minimum_healthy_percent <= 100
    )
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Upper limit on the number of running tasks during a deployment, as a percentage of desired_count."
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100
    error_message = "deployment_maximum_percent must be greater than or equal to 100."
  }
}

############################################
# Task definition settings
############################################

variable "cpu" {
  description = "Task-level CPU units for the Fargate task definition."
  type        = number

  validation {
    condition     = var.cpu > 0
    error_message = "cpu must be greater than 0."
  }
}

variable "memory" {
  description = "Task-level memory (MiB) for the Fargate task definition."
  type        = number

  validation {
    condition     = var.memory > 0
    error_message = "memory must be greater than 0."
  }
}

variable "runtime_platform" {
  description = <<-EOT
  Optional runtime platform override for the task definition.

  Defaults:
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  EOT

  type = object({
    operating_system_family = optional(string)
    cpu_architecture        = optional(string)
  })

  default = null

  validation {
    condition = (
      var.runtime_platform == null ||
      try(var.runtime_platform.operating_system_family, null) == null ||
      try(contains(["LINUX"], upper(var.runtime_platform.operating_system_family)), true)
    )
    error_message = "If provided, runtime_platform.operating_system_family must be LINUX in v1."
  }

  validation {
    condition = (
      var.runtime_platform == null ||
      try(var.runtime_platform.cpu_architecture, null) == null ||
      try(contains(["X86_64", "ARM64"], upper(var.runtime_platform.cpu_architecture)), true)
    )
    error_message = "If provided, runtime_platform.cpu_architecture must be X86_64 or ARM64."
  }
}

variable "ephemeral_storage_gib" {
  description = "Optional ephemeral storage size in GiB for the task definition. If null, AWS default is used."
  type        = number
  default     = null

  validation {
    condition = (
      var.ephemeral_storage_gib == null ||
      try(var.ephemeral_storage_gib >= 21 && var.ephemeral_storage_gib <= 200, true)
    )
    error_message = "ephemeral_storage_gib must be null or between 21 and 200."
  }
}

############################################
# Primary container definition
############################################

variable "container" {
  description = <<-EOT
  Configuration for the single primary application container.

  Fields:
    - image (required): container image URI
    - port (required): application port exposed by the container
    - optional command / entrypoint
    - optional environment variables
    - optional secrets list for ECS valueFrom wiring
    - optional container health check
  EOT

  type = object({
    name        = optional(string)
    image       = string
    port        = number
    essential   = optional(bool, true)
    command     = optional(list(string))
    entrypoint  = optional(list(string))
    environment = optional(map(string), {})
    secrets = optional(list(object({
      name       = string
      value_from = string
    })), [])
    readonly_root_filesystem = optional(bool, false)
    health_check = optional(object({
      command      = list(string)
      interval     = optional(number)
      timeout      = optional(number)
      retries      = optional(number)
      start_period = optional(number)
    }))
  })

  validation {
    condition     = length(trimspace(var.container.image)) > 0
    error_message = "container.image must not be empty."
  }

  validation {
    condition     = var.container.port >= 1 && var.container.port <= 65535
    error_message = "container.port must be between 1 and 65535."
  }

  validation {
    condition = (
      try(var.container.name, null) == null ||
      length(trimspace(var.container.name)) > 0
    )
    error_message = "container.name must be null or a non-empty string."
  }

  validation {
    condition = alltrue([
      for key, value in var.container.environment :
      length(trimspace(key)) > 0 && value != null
    ])
    error_message = "container.environment must not contain empty keys or null values."
  }

  validation {
    condition = alltrue([
      for secret in var.container.secrets :
      length(trimspace(secret.name)) > 0 && length(trimspace(secret.value_from)) > 0
    ])
    error_message = "Each container.secrets entry must include non-empty name and value_from values."
  }

  validation {
    condition = (
      try(var.container.health_check, null) == null ||
      try(length(var.container.health_check.command) > 0, true)
    )
    error_message = "If provided, container.health_check.command must contain at least one item."
  }
}

############################################
# CloudWatch logging
############################################

variable "enable_cloudwatch_logging" {
  description = "Whether to configure the container to send logs to a module-managed CloudWatch Log Group."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = <<-EOT
  Optional CloudWatch Log Group name.

  If null, the module uses:
    "/<project_name>/<environment>/ecs/<service_name>"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.log_group_name == null || length(trimspace(coalesce(var.log_group_name, ""))) > 0
    error_message = "log_group_name must be null or a non-empty string."
  }
}

variable "log_retention_in_days" {
  description = "Retention period in days for the module-managed CloudWatch Log Group."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365,
      400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_in_days)
    error_message = "log_retention_in_days must be a valid CloudWatch Logs retention value."
  }
}

variable "log_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the module-managed CloudWatch Log Group."
  type        = string
  default     = null

  validation {
    condition = (
      var.log_kms_key_arn == null ||
      can(regex("^arn:aws(-[a-z]+)?:kms:[a-z0-9-]+:[0-9]{12}:key\\/.+$", var.log_kms_key_arn))
    )
    error_message = "log_kms_key_arn must be null or a valid KMS key ARN."
  }
}

variable "log_stream_prefix" {
  description = "Stream prefix used by the awslogs container log driver."
  type        = string
  default     = "ecs"

  validation {
    condition     = length(trimspace(var.log_stream_prefix)) > 0
    error_message = "log_stream_prefix must not be empty."
  }
}

############################################
# IAM guardrails and extensions
############################################

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN applied to the task execution role and task role."
  type        = string
  default     = null

  validation {
    condition = (
      var.permissions_boundary_arn == null ||
      length(trimspace(coalesce(var.permissions_boundary_arn, ""))) > 0
    )
    error_message = "permissions_boundary_arn must be null or a non-empty ARN string."
  }
}

variable "task_role_policy_json" {
  description = "List of additional IAM policy JSON documents to attach inline to the task role."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for policy in var.task_role_policy_json :
      can(jsondecode(policy))
    ])
    error_message = "Each value in task_role_policy_json must be valid JSON."
  }
}

variable "execution_role_policy_json" {
  description = "List of additional IAM policy JSON documents to attach inline to the task execution role."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for policy in var.execution_role_policy_json :
      can(jsondecode(policy))
    ])
    error_message = "Each value in execution_role_policy_json must be valid JSON."
  }
}

############################################
# Optional load balancer integration
############################################

variable "load_balancer" {
  description = <<-EOT
  Optional ALB target group attachment for the ECS service.

  Fields:
    - target_group_arn (required)
    - container_port (optional; defaults to container.port)
  EOT

  type = object({
    target_group_arn = string
    container_port   = optional(number)
  })

  default = null

  validation {
    condition = (
      var.load_balancer == null ||
      length(trimspace(var.load_balancer.target_group_arn)) > 0
    )
    error_message = "If provided, load_balancer.target_group_arn must not be empty."
  }

  validation {
    condition = (
      var.load_balancer == null ||
      try(var.load_balancer.container_port, null) == null ||
      (var.load_balancer.container_port >= 1 && var.load_balancer.container_port <= 65535)
    )
    error_message = "If provided, load_balancer.container_port must be between 1 and 65535."
  }
}

############################################
# Security group ingress / egress model
############################################

variable "ingress_source_security_group_ids" {
  description = "List of source security group IDs allowed to reach the service container port."
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
  description = "List of IPv4 CIDRs allowed for outbound traffic from the service security group."
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
