# TF-Template-Stack

A modular Terraform configuration for deploying applications on AWS with environment-specific deployments.

## Structure

- **envs/**: Environment-specific configurations (dev, stage, prod)
- **modules/**: Reusable Terraform modules 


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Environments

- **dev** - Development environment
- **stage** - Staging environment  
- **prod** - Production environment

## Configuration

See environment-specific `*.tfvars` files in `envs/` directories.
