############################################
# Identity + tagging
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
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
############################################
# Enable / Mode
############################################

variable "enabled" {
  description = "Whether to create NAT Gateway resources and routes."
  type        = bool
  default     = true
}

variable "mode" {
  description = "NAT mode: per_az (recommended) or single (cheaper dev)."
  type        = string
  default     = "per_az"

  validation {
    condition     = contains(["per_az", "single"], var.mode)
    error_message = "mode must be 'per_az' or 'single'."
  }
}

variable "create_routes" {
  description = "Whether to create default routes in private route tables pointing to the NAT Gateway(s)."
  type        = bool
  default     = true
}

############################################
# Wiring inputs from network module
############################################

variable "public_subnet_ids_by_az" {
  description = "Map of AZ name => public subnet ID (from modules/network). Required when enabled=true."
  type        = map(string)
  default     = {}
}

variable "private_route_table_ids_by_az" {
  description = "Map of AZ name => private route table ID (from modules/network). Required when enabled=true."
  type        = map(string)
  default     = {}
}

############################################
# EIP handling (optional advanced)
############################################

variable "reuse_eip_allocation_ids" {
  description = "Optional list of existing EIP allocation IDs to reuse. If provided, the module will not create new EIPs."
  type        = list(string)
  default     = null
}