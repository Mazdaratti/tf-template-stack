# Bootstrap (dev)

This bootstrap stack provisions the Terraform remote backend (S3 + DynamoDB) using `modules/remote_backend`.

It also generates `envs/dev/backend.tf` automatically after apply.

## Usage

```sh
cd bootstrap/dev
terraform init
terraform apply

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
| <a name="provider_local"></a> [local](#provider\_local) | 2.6.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_remote_backend"></a> [remote\_backend](#module\_remote\_backend) | ../../modules/remote_backend | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.backend_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where bootstrap resources will be created. | `string` | `"eu-central-1"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags applied to resources. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/stage/prod). Used for naming and for writing env backend.tf. | `string` | `"dev"` | no |
| <a name="input_lock_table_name"></a> [lock\_table\_name](#input\_lock\_table\_name) | Optional override for the Terraform lock DynamoDB table name. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Optional override for the Terraform state S3 bucket name. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tf_state_bucket_arn"></a> [tf\_state\_bucket\_arn](#output\_tf\_state\_bucket\_arn) | ARN of the S3 bucket used for Terraform state. |
| <a name="output_tf_state_bucket_name"></a> [tf\_state\_bucket\_name](#output\_tf\_state\_bucket\_name) | Name of the S3 bucket used for Terraform state. |
| <a name="output_tf_state_lock_table_arn"></a> [tf\_state\_lock\_table\_arn](#output\_tf\_state\_lock\_table\_arn) | ARN of the DynamoDB table used for Terraform state locking. |
| <a name="output_tf_state_lock_table_name"></a> [tf\_state\_lock\_table\_name](#output\_tf\_state\_lock\_table\_name) | Name of the DynamoDB table used for Terraform state locking. |
<!-- END_TF_DOCS -->