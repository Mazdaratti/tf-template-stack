provider "aws" {
  region = "eu-central-1"
}

module "network" {
  source = "../../"

  project_name = "network-example"
  environment  = "dev"

  vpc_cidr = "10.20.0.0/16"

  # Explicit control path
  azs = [
    "eu-central-1a",
    "eu-central-1b"
  ]

  public_subnet_cidrs = [
    "10.20.10.0/24",
    "10.20.11.0/24"
  ]

  private_subnet_cidrs = [
    "10.20.110.0/24",
    "10.20.111.0/24"
  ]

  common_tags = {
    Team = "Platform"
  }
}
