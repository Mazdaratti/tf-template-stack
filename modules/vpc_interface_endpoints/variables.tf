############################################
# Identity + tagging
############################################

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)."
  type        = string
}

variable "common_tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

############################################
# Core wiring
############################################

variable "vpc_id" {
  description = "ID of the VPC where interface endpoints will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (typically private subnets) for interface endpoints."
  type        = list(string)
}

############################################
# Interface endpoints configuration
############################################

variable "interface_endpoints" {
  description = <<EOT
Map of interface endpoints to create.

Key   = service identifier (e.g. ssm, ec2messages, logs)
Value = object with enable flag and optional private DNS control.

Example:
{
  ssm = {
    enabled             = true
    private_dns_enabled = true
  }
}
EOT

  type = map(object({
    enabled             = bool
    private_dns_enabled = optional(bool, true)
  }))

  default = {}
}

############################################
# Security group handling
############################################

variable "security_group_ids" {
  description = "Existing security group IDs to attach to interface endpoints. Preferred in real-world setups."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a minimal security group for the interface endpoints."
  type        = bool
  default     = false
}

############################################
# Optional endpoint policies
############################################

variable "endpoint_policy_json" {
  description = <<EOT
Optional map of service => policy JSON to attach to interface endpoints.

Policies are usually defined in envs/<env>/endpoint_policies.tf
and passed into this module.

If a service key is omitted, AWS default endpoint policy is used.
EOT

  type    = map(string)
  default = {}
}
