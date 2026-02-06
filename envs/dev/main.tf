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

module "gateway_endpoints" {
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
}
