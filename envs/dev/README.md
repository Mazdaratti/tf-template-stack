# Development Environment

Configuration for the development environment deployment.

## Prerequisites

- Terraform >= 0.13
- AWS credentials configured

## Usage

```shell
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
