# VPC Module

This module creates a VPC with public and private subnets across multiple availability zones.

## Features

- VPC with configurable CIDR block
- Public subnets with Internet Gateway
- Private subnets with NAT Gateway (optional)
- Route tables and route associations
- Network ACLs

## Usage

```hcl
module "vpc" {
  source = "../modules/vpc"

  vpc_name           = "todo-app-vpc"
  cidr_block         = "10.0.0.0/16"
  enable_nat_gateway = true
  tags               = local.common_tags
}
```

## Inputs

See `variables.tf` for detailed input descriptions.

## Outputs

See `outputs.tf` for detailed output descriptions.
