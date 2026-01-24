# Production Environment

Configuration for the production environment deployment.

## Prerequisites

- Terraform >= 0.13
- AWS credentials configured

## Usage

```shell
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
