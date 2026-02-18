# TF-Template-Stack

A modular Terraform configuration for deploying applications on AWS with environment-specific deployments.

## Structure

- **envs/**: Environment root modules (dev, stage, prod). Each env calls reusable modules.
- **modules/**: Reusable Terraform modules (copied/added as needed per project).
- **bootstrap/** (optional): One-time prerequisites per environment (remote state, GitHub OIDC, IAM).
- **.vscode/**: Editor tasks/settings for repeatable workflows.

## Workflow

- Use VS Code tasks to run `fmt`, `tflint`, and `terraform-docs`.
- Generate docs for any env/module folder by opening a file in that folder and running:
  **terraform-docs: Generate README (current folder)**.

## Modules

- **network** — VPC + subnets + route tables (no NAT)
- **nat_gateway** — NAT Gateway(s) + private outbound routes
- **vpc_gateway_endpoints** — Gateway endpoints (S3, DynamoDB)
- **vpc_interface_endpoints** — Interface endpoints (PrivateLink services)
- **kms_keys** — Reusable KMS key creation with safe default policy
- **s3_bucket** — Secure-by-default S3 bucket with encryption, lifecycle, logging support
- **remote_backend** — S3 + DynamoDB remote state backend (bootstrap use)



## Recommended order

1) `bootstrap/dev` (remote backend + OIDC)
2) `envs/dev` (network, nat, compute modules...)

## Environments

- **dev** - Development environment
- **stage** - Staging environment  
- **prod** - Production environment

## Configuration

See environment-specific `*.tfvars` files in `envs/` directories.
