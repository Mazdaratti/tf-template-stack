############################################
# Core environment variables
############################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for naming/tagging across all modules. Must be unique across all projects in the account."
  type        = string
}

variable "common_tags" {
  description = "Common tags passed into modules (merged with enforced tags inside each module)."
  type        = map(string)
  default     = {}
}

############################################
# Network module (hybrid configuration)
############################################

variable "enable_dns_support" {
  description = "Whether DNS resolution is supported for the VPC."
  type        = bool
  default     = true

}

variable "enable_dns_hostnames" {
  description = "Whether instances in the VPC get DNS hostnames."
  type        = bool
  default     = true

}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Optional explicit list of availability zones to use. If set, az_count is ignored."
  type        = list(string)
  default     = null
}

variable "az_count" {
  description = "The number of availability zones to use if explicit AZ list is not provided (module will pick the first N AZs in region)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1
    error_message = "az_count must be >= 1."
  }
}

variable "create_public_subnets" {
  description = "Whether to create public subnets and public routing (IGW + public route table)."
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Whether to create private subnets and private routing (NAT + private route table)."
  type        = bool
  default     = true
}

variable "public_subnet_count" {
  description = "Number of public subnets to create if explicit public CIDRs are not provided."
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 0
    error_message = "public_subnet_count must be >= 0."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create if explicit private CIDRs are not provided."
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 0
    error_message = "private_subnet_count must be >= 0."
  }
}

variable "public_subnet_cidrs" {
  description = "Optional explicit list of CIDR blocks for public subnets. If set, public_subnet_count is ignored."
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "Optional explicit list of CIDR blocks for private subnets. If set, private_subnet_count is ignored."
  type        = list(string)
  default     = null
}

variable "map_public_ip_on_launch" {
  description = "Whether public subnets should map public IPs on launch."
  type        = bool
  default     = true
}



