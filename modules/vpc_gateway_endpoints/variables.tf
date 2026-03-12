############################################
# Identity + tagging
############################################

variable "project_name" {
  description = "Project name used for naming/tagging."
  type        = string
}

variable "environment" {
  description = "Environment name used for naming/tagging (e.g., dev, stage, prod)."
  type        = string
}

variable "common_tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

############################################
# Wiring inputs
############################################

variable "vpc_id" {
  description = "The VPC ID where gateway endpoints will be created."
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs to attach the gateway endpoints to (typically private route tables)."
  type        = list(string)
  default     = []
}


variable "region" {
  description = "AWS region used to build endpoint service names. If null, uses the provider region."
  type        = string
  default     = null
}

############################################
# Endpoint selection
############################################

variable "gateway_endpoints" {
  description = "Which gateway endpoints to create."
  type = object({
    s3       = bool
    dynamodb = bool
  })
  default = {
    s3       = true
    dynamodb = true
  }
}

############################################
# Optional endpoint policies
############################################

variable "endpoint_policy_json" {
  description = "Optional map of service => policy JSON (keys: s3, dynamodb). If omitted for a service, AWS default policy is used."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k in keys(var.endpoint_policy_json) : contains(["s3", "dynamodb"], k)
    ])
    error_message = "endpoint_policy_json keys must be only: s3, dynamodb."
  }
}





