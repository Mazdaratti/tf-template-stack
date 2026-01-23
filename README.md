# Todo App Infrastructure

Terraform configuration for the Todo App infrastructure deployment across multiple environments (dev, stage, prod).

## Directory Structure

- `global/` - Global configuration and data sources
- `modules/` - Reusable Terraform modules (VPC, ALB, ECS Service)
- `envs/` - Environment-specific configurations (dev, stage, prod)
- `.vscode/` - VS Code configuration files

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- tflint for linting
- terraform-docs for documentation generation

## Usage

### Initialize Terraform

```bash
cd envs/dev  # or stage, prod
terraform init
```

### Validate Configuration

```bash
terraform validate
terraform plan
```

### Apply Configuration

```bash
terraform apply
```

## Modules

### VPC Module
Creates VPC with subnets, NAT gateways, and route tables.

### ALB Module
Creates Application Load Balancer for routing traffic.

### ECS Service Module
Creates ECS service for container orchestration.

## Environments

- **dev** - Development environment
- **stage** - Staging environment  
- **prod** - Production environment

## Configuration

See environment-specific `*.tfvars` files in `envs/` directories.
