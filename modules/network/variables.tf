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
# VPC
############################################

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

############################################
# Availability Zones (hybrid)
############################################

variable "azs" {
  description = "A list of availability zones to use for the VPC subnets."
  type        = list(string)
  default     = null
}

variable "az_count" {
  description = "The number of availability zones to use if 'azs' is not provided."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1
    error_message = "az_count must be >= 1."
  }
}

############################################
# Subnet creation toggles
############################################

variable "create_public_subnets" {
  description = "A boolean flag to enable/disable creation of public subnets."
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "A boolean flag to enable/disable creation of private subnets."
  type        = bool
  default     = true
}

############################################
# Public subnets (hybrid)
############################################

variable "public_subnet_count" {
  description = "The number of public subnets to create if 'create_public_subnets' is true."
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 0
    error_message = "public_subnet_count must be >= 0."
  }
}

variable "public_subnet_cidrs" {
  description = "Optional explicit list of CIDR blocks for public subnets.If set, public_subnet_count is ignored."
  type        = list(string)
  default     = null
}

variable "map_public_ip_on_launch" {
  description = "A boolean flag to enable/disable mapping public IPs on launch for public subnets."
  type        = bool
  default     = true
}

############################################
# Private subnets (hybrid)
############################################

variable "private_subnet_count" {
  description = "The number of private subnets to create if 'create_private_subnets' is true."
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 0
    error_message = "private_subnet_count must be >= 0."
  }
}

variable "private_subnet_cidrs" {
  description = "Optional explicit list of CIDR blocks for private subnets. If set, private_subnet_count is ignored."
  type        = list(string)
  default     = null
}


