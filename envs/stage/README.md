# Staging Environment

Configuration for the staging environment deployment.

## Prerequisites

- Terraform >= 0.13
- AWS credentials configured

## Usage

```shell
terraform init
terraform plan -var-file=stage.tfvars
terraform apply -var-file=stage.tfvars
```

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
