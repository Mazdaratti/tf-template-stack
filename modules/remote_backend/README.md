# Remote Backend Module

Creates secure remote state backend infrastructure for Terraform on AWS.

## Features

- S3 bucket with versioning, encryption (AES-256), and public access blocking
- Compatible with modern S3 backend lockfile-based state locking
- Enforced and customizable tags
- Built-in lifecycle protection on the state bucket
- Minimal required inputs for reusability across projects

## Usage

```hcl
module "remote_backend" {
  source = "../modules/remote_backend"

  project_name = "my-project"
  environment  = "stage"
  common_tags  = local.common_tags
}
```

## Examples

The `examples/` directory contains runnable configurations demonstrating different use cases for this module.

### `basic_usage/`

A **minimal working example** of the module showing:
- Basic provider configuration
- Module provisioning for a persistent non-dev environment
- Output retrieval

**Usage:**
```hcl
module "remote_backend" {
  source = "../.."

  project_name = "remote-backend-test"
  environment  = "stage"

  common_tags = {
    Project     = "tf-template-stack"
    ManagedBy   = "Terraform"
    Environment = "Staging"
    Team        = "DevOps"
    Module      = "remote_backend"
  }
}
```

### `custom_bucket_name/`

An **advanced example** demonstrating production-oriented usage with explicit naming:
- Uses `prod` environment designation
- Overrides the generated bucket name explicitly
- Includes additional `CriticalData = "true"` tag for sensitive workloads

**Usage:**
```hcl
module "remote_backend" {
  source = "../.."

  project_name      = "remote-backend-test"
  environment       = "prod"
  state_bucket_name = "remote-backend-test-prod-tf-state-example"

  common_tags = {
    Project      = "tf-template-stack"
    ManagedBy    = "Terraform"
    Environment  = "Production"
    Team         = "DevOps"
    Module       = "remote_backend"
    CriticalData = "true"
  }
}
```

## Inputs and Outputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_id.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, stage, prod). Used in resource naming. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project. Used in resource naming. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Override for the S3 bucket name. If not provided, derived from project\_name and environment. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tf_state_bucket_arn"></a> [tf\_state\_bucket\_arn](#output\_tf\_state\_bucket\_arn) | The ARN of the S3 bucket for Terraform state. |
| <a name="output_tf_state_bucket_name"></a> [tf\_state\_bucket\_name](#output\_tf\_state\_bucket\_name) | The name of the S3 bucket for Terraform state. |
<!-- END_TF_DOCS -->
