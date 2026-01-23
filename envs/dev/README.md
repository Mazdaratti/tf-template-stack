# Development Environment

This directory contains Terraform configuration for the development environment.

## Prerequisites

- AWS credentials configured locally
- Terraform initialized (`terraform init`)

## Usage

### Plan changes
```bash
terraform plan -var-file="dev.tfvars"
```

### Apply changes
```bash
terraform apply -var-file="dev.tfvars"
```

### Destroy resources
```bash
terraform destroy -var-file="dev.tfvars"
```

## Configuration

Edit `dev.tfvars` to modify environment-specific variables.

## Troubleshooting

For backend errors, ensure the S3 bucket and DynamoDB table exist in AWS.
