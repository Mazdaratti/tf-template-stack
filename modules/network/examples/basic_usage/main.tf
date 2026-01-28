provider "aws" {
  region = "eu-central-1"
}

module "network" {
  source = "../../"

  project_name = "network-example"
  environment  = "dev"

  vpc_cidr = "10.10.0.0/16"

  # Hybrid defaults path (no explicit azs or subnet CIDRs)
  az_count             = 2
  public_subnet_count  = 2
  private_subnet_count = 2

  common_tags = {
    Team = "Platform"
  }
}
