# Development Environment - Main Configuration

###################################
# MODULE - NETWORK
###################################

module "network" {
  source = "../../modules/network"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # VPC
  vpc_cidr             = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  # AZ Selection
  azs      = var.azs
  az_count = var.az_count

  # Subnet toggles
  create_public_subnets  = var.create_public_subnets
  create_private_subnets = var.create_private_subnets

  # Hybrid subnet sizing
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Public subnet behavior
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

###################################
# MODULE - NAT GATEWAY 
###################################

module "nat_gateway" {
  source = "../../modules/nat_gateway"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs (AZ-name keyed)
  public_subnet_ids_by_az       = module.network.public_subnet_ids_by_az
  private_route_table_ids_by_az = module.network.private_route_table_ids_by_az

  # Defaults for dev (can be overridden via variables.tf)
  enabled       = var.enable_nat_gateway
  mode          = var.nat_gateway_mode
  create_routes = var.nat_create_routes

  # Optional: reuse existing EIPs (leave null to create new EIPs)
  reuse_eip_allocation_ids = var.nat_reuse_eip_allocation_ids
}

###################################
# MODULE - VPC GATEWAY ENDPOINTS (S3, DynamoDB)
###################################

module "vpc_gateway_endpoints" {
  source = "../../modules/vpc_gateway_endpoints"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs
  vpc_id = module.network.vpc_id
  # Recommended: attach gateway endpoints to private route tables
  route_table_ids = values(module.network.private_route_table_ids_by_az)

  # Enable both endpoints by default in dev for testing/demo purposes
  gateway_endpoints = {
    s3       = true
    dynamodb = true
  }

  # Optional: define endpoint policies using aws_iam_policy_document
  # If a service is omitted, AWS default policy is used.
  # endpoint_policy_json = {
  #   s3       = data.aws_iam_policy_document.vpce_s3_restricted.json
  #   dynamodb = data.aws_iam_policy_document.vpce_dynamodb_restricted.json
  # }
}

############################################
# VPC Interface Endpoints (PrivateLink)
############################################

module "vpc_interface_endpoints" {
  source = "../../modules/vpc_interface_endpoints"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Wiring from network module outputs
  vpc_id = module.network.vpc_id
  # Recommended: attach gateway endpoints to private route tables
  subnet_ids = module.network.private_subnet_ids

  # Simple default for this template: module-managed SG
  create_security_group = true

  # Real-world option (recommended in platforms): external/shared SG
  # - create_security_group = false
  # - security_group_ids    = [aws_security_group.vpce_shared.id]
  #
  # security_group_ids = [aws_security_group.vpce_shared.id]


  # Endpoints baseline for private management access + common platform services.
  interface_endpoints = {
    ssm            = { enabled = true }
    ssmmessages    = { enabled = true }
    ec2messages    = { enabled = true }
    logs           = { enabled = true }
    secretsmanager = { enabled = true }
  }

  # Optional: define endpoint policies using aws_iam_policy_document
  # If a service is omitted, AWS default policy is used.
  # endpoint_policy_json = {
  #   secretsmanager = data.aws_iam_policy_document.vpce_secretsmanager_restricted.json
  #   logs           = data.aws_iam_policy_document.vpce_logs_restricted.json
  # }
}

###################################
# MODULE - KMS KEYS
###################################

module "kms_keys" {
  source = "../../modules/kms_keys"

  # Identity + tags
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Optional:
  # alias_prefix = "${var.project_name}-${var.environment}"

  #***********************************
  # Foundation baseline keys (dev)
  #***********************************

  # Keep this generic and aligned with upcoming modules:
  # - logs: for logging_baseline / vpc_flow_logs (CloudWatch Logs)
  # - s3: for secure s3 bucket baseline
  # - secretsmanager: common platform primitive
  # - ssm: common platform primitive (SecureString)


  keys = {
    logs = {
      description = "KMS key for log encryption"
    }

    s3 = {
      description = "KMS key for S3 bucket encryption"
    }

    secretsmanager = {
      description = "KMS key for Secrets Manager"
    }

    ssm = {
      description = "KMS key for SSM Parameter Store SecureString"
    }
  }

  # Optional: custom key policies can be defined in envs/dev/kms_key_policies.tf
  # and passed per key as `policy = data.aws_iam_policy_document.<name>.json`
}
