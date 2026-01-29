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