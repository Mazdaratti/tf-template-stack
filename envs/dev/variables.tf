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

############################################
# NAT Gateway module (optioanal)
############################################

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway resources for private outbound internet access."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT mode: per_az (recommended) or single (cheaper dev)."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["per_az", "single"], var.nat_gateway_mode)
    error_message = "NAT mode must be one of 'per_az' or 'single'."
  }
}

variable "nat_create_routes" {
  description = "Whether to create default routes in private route tables pointing to NAT."
  type        = bool
  default     = true
}

variable "nat_reuse_eip_allocation_ids" {
  description = "Optional list of existing EIP allocation IDs to reuse. If null, the module creates new EIPs."
  type        = list(string)
  default     = null
}

############################################
# ECS Cluster module (baseline)
############################################

variable "ecs_cluster_name" {
  description = "Optional ECS cluster name override. If null, module default naming is used."
  type        = string
  default     = null

  validation {
    condition     = var.ecs_cluster_name == null ? true : length(trimspace(var.ecs_cluster_name)) > 0
    error_message = "ecs_cluster_name must be null or a non-empty string."
  }
}

variable "ecs_enable_container_insights" {
  description = "Whether to enable ECS Container Insights for the dev cluster baseline."
  type        = bool
  default     = true
}

############################################
# ECS Fargate Service module (dev workload)
############################################

variable "ecs_service_image_uri" {
  description = <<-EOT
  Container image URI for the dev ECS Fargate service.

  This is the only workload-specific input exposed at the env layer in v1.
  Service sizing, port, subnet placement, logging, and ALB integration stay
  opinionated in envs/dev to keep the baseline small and predictable.
  EOT
  type        = string

  validation {
    condition     = length(trimspace(var.ecs_service_image_uri)) > 0
    error_message = "ecs_service_image_uri must not be empty."
  }
}

