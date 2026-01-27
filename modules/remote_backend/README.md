# Remote Backend Module

Creates secure remote state backend infrastructure for Terraform on AWS.

## Features

- S3 bucket with versioning, encryption (AES-256), and public access blocking
- DynamoDB table for state locking with PAY_PER_REQUEST billing
- Point-in-time recovery enabled on DynamoDB
- Enforced and customizable tags
- Optional lifecycle protection with prevent_destroy
- Minimal required inputs for reusability across projects

## Usage

`hcl
module "remote_backend" {
  source = "../modules/remote_backend"

  project_name = "my-project"
  environment  = "dev"
  common_tags  = local.common_tags
}
`

## Examples

The `examples/` directory contains runnable configurations demonstrating different use cases for this module.

### `basic_usage/`

A **minimal working example** of the module showing:
- Basic provider configuration
- Module provisioning with standard tags
- Output retrieval

**Usage:**
```hcl
module "remote_backend" {
  source = "../.."

  project_name = "remote-backend-test"
  environment  = "dev"

  common_tags = {
    Project     = "tf-template-stack"
    ManagedBy   = "Terraform"
    Environment = "Testing"
    Team        = "DevOps"
    Module      = "remote_backend"
  }
}
```

### `with_prevent_destroy/`

An **advanced example** demonstrating production-safe configuration with lifecycle protection:
- Enables `prevent_destroy = true` to protect against accidental deletion
- Uses `prod` environment designation
- Includes additional `CriticalData = "true"` tag for sensitive workloads

**Usage:**
```hcl
module "remote_backend" {
  source = "../.."

  project_name    = "remote-backend-test"
  environment     = "prod"
  prevent_destroy = true

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
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
| <a name="input_lock_table_name"></a> [lock\_table\_name](#input\_lock\_table\_name) | Override for the DynamoDB table name. If not provided, derived from project\_name and environment. | `string` | `null` | no |
| <a name="input_prevent_destroy"></a> [prevent\_destroy](#input\_prevent\_destroy) | Enable lifecycle prevent\_destroy on S3 bucket and DynamoDB table. | `bool` | `false` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project. Used in resource naming. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Override for the S3 bucket name. If not provided, derived from project\_name and environment. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lock_table_arn"></a> [lock\_table\_arn](#output\_lock\_table\_arn) | The ARN of the DynamoDB table for state locking. |
| <a name="output_lock_table_name"></a> [lock\_table\_name](#output\_lock\_table\_name) | The name of the DynamoDB table for state locking. |
| <a name="output_state_bucket_arn"></a> [state\_bucket\_arn](#output\_state\_bucket\_arn) | The ARN of the S3 bucket for Terraform state. |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | The name of the S3 bucket for Terraform state. |
<!-- END_TF_DOCS -->
