############################################
# Example: basic_usage
############################################
#
# This example is self-contained and runnable.
#
# It demonstrates:
# - Creating a minimal VPC for private DNS scope
# - Creating one private hosted zone
# - Associating the zone with the VPC
# - Creating a small, baseline set of records
############################################

############################################
# Provider
############################################

provider "aws" {
  # Keep region explicit in examples so behavior
  # is predictable for new users.
  region = "eu-central-1"
}

############################################
# Minimal VPC
############################################
#
# Private Route53 zones require at least one
# VPC association, so this example creates a
# dedicated VPC as DNS scope.
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "route53-private-zones-example"
  }
}

############################################
# Module: route53_private_zones
############################################
#
# Inputs:
# - project_name/environment/common_tags for
#   standardized tagging
# - zones map defining zone name, VPC links,
#   and optional baseline records
############################################

module "route53_private_zones" {
  source = "../../"

  ##########################################
  # Identity + tags
  ##########################################
  project_name = "route53-private-zones-example"
  environment  = "dev"

  common_tags = {
    Owner = "example"
  }

  ##########################################
  # Zones
  ##########################################
  zones = {
    internal = {
      # Final hosted zone name.
      domain_name = "dev.internal"

      # At least one association is required
      # for private hosted zones.
      vpc_associations = [
        {
          vpc_id = aws_vpc.this.id
        }
      ]

      ######################################
      # Optional records
      #
      # Record key conventions:
      # - "@" = apex record (dev.internal)
      # - "api" = api.dev.internal
      ######################################
      records = {
        "@" = {
          type   = "TXT"
          ttl    = 300
          values = ["zone apex record"]
        }

        api = {
          type   = "CNAME"
          ttl    = 300
          values = ["internal-api.example.local"]
        }
      }
    }
  }
}

