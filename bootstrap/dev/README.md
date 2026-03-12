# Bootstrap (dev)

This folder contains the **one-time bootstrap stack** for the `dev` environment.

It provisions prerequisites needed before you can deploy real infrastructure via Terraform:

- **Remote Terraform state backend**
  - S3 bucket for state
  - DynamoDB table for state locking
- **GitHub Actions OIDC authentication**
  - OIDC provider for GitHub
  - IAM role that GitHub Actions deployment workflows can assume (main branch only)

It also **generates `envs/dev/backend.tf` automatically** after apply, so you don’t need to create the backend configuration manually.

---

## What this bootstrap stack is for

Run this stack when you:
- create a new AWS account / new environment
- set up a new infrastructure project
- want GitHub Actions deployment workflows to provision infrastructure using Terraform

You typically run it **once**, and only update it if you change backend or IAM/OIDC settings.

---

## GitHub Actions OIDC (hardened deployment model)

This stack creates an IAM role for GitHub Actions:

- ✅ Trust is restricted to **your repo + `main` branch**
- ✅ By default, permissions are separated into:
  - Terraform state bucket access (S3)
  - Terraform lock table access (DynamoDB)
  - deploy permissions for the currently implemented `envs/dev` infrastructure
- ✅ Optional repo-aligned permissions boundary can be attached to the role as a guardrail

Important boundary:

- bootstrap remains **manual**
- the GitHub Actions role is intended for **deployment workflows**, not CI validation
- the validation workflow added in the repository does **not** assume this role

### Legacy admin escape hatch
If you want broad permissions during early prototyping, you can temporarily enable:

- `attach_admin_policy = true`

⚠️ This attaches `AdministratorAccess`. It is kept only as a legacy/prototyping escape hatch and is **not** part of the hardened recommended path.

### Permissions boundary
This stack can also create a **repo-aligned permissions boundary** for the GitHub Actions role.

This boundary is intended as a practical guardrail for this repository's current IAM model. It is still not a substitute for centrally managed organization-wide guardrails in a larger environment.

---

## Usage

```sh
cd bootstrap/dev
cp terraform.tfvars.example terraform.tfvars
```
Edit terraform.tfvars and set the required values
At minimum, set:

- `project_name`
- `github_org`
- `github_repo`

Optional values such as `github_branch`, naming overrides, and guardrail toggles can then be adjusted as needed.

After values are set run:

```sh
terraform init
terraform apply
```

After bootstrap is applied:

- `envs/dev/backend.tf` is generated automatically
- the GitHub Actions deployment role ARN is available as an output
- future deployment workflows can use OIDC to assume the role

The current recommended sequence is:

1. run bootstrap manually
2. deploy infrastructure from `envs/dev`
3. use GitHub Actions CI for validation only
4. use the OIDC role later for deployment automation

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.36.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_remote_backend"></a> [remote\_backend](#module\_remote\_backend) | ../../modules/remote_backend | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.github_actions_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_actions_deploy_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_actions_state_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.github_actions_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.github_actions_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_actions_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [local_file.backend_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_iam_policy_document.github_actions_deploy_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_actions_state_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attach_admin_policy"></a> [attach\_admin\_policy](#input\_attach\_admin\_policy) | Legacy prototyping-only escape hatch. If true, attach AWS managed AdministratorAccess to the GitHub Actions role. Keep disabled for the hardened deployment model. | `bool` | `false` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where bootstrap resources will be created. | `string` | `"eu-central-1"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags applied to resources. | `map(string)` | `{}` | no |
| <a name="input_create_permissions_boundary"></a> [create\_permissions\_boundary](#input\_create\_permissions\_boundary) | If true, create and attach the repo-aligned permissions boundary to the GitHub Actions role. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/stage/prod). Used for naming and for writing env backend.tf. | `string` | `"dev"` | no |
| <a name="input_github_branch"></a> [github\_branch](#input\_github\_branch) | GitHub branch name allowed to assume the GitHub Actions deploy role. | `string` | `"main"` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization/user name that owns the repository. | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository name. | `string` | n/a | yes |
| <a name="input_lock_table_name"></a> [lock\_table\_name](#input\_lock\_table\_name) | Optional override for the Terraform lock DynamoDB table name. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Optional override for the Terraform state S3 bucket name. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_github_actions_role_arn"></a> [github\_actions\_role\_arn](#output\_github\_actions\_role\_arn) | ARN of the IAM role created for GitHub Actions OIDC. |
| <a name="output_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#output\_github\_oidc\_provider\_arn) | ARN of the GitHub OIDC provider. |
| <a name="output_tf_state_bucket_arn"></a> [tf\_state\_bucket\_arn](#output\_tf\_state\_bucket\_arn) | ARN of the S3 bucket used for Terraform state. |
| <a name="output_tf_state_bucket_name"></a> [tf\_state\_bucket\_name](#output\_tf\_state\_bucket\_name) | Name of the S3 bucket used for Terraform state. |
| <a name="output_tf_state_lock_table_arn"></a> [tf\_state\_lock\_table\_arn](#output\_tf\_state\_lock\_table\_arn) | ARN of the DynamoDB table used for Terraform state locking. |
| <a name="output_tf_state_lock_table_name"></a> [tf\_state\_lock\_table\_name](#output\_tf\_state\_lock\_table\_name) | Name of the DynamoDB table used for Terraform state locking. |
<!-- END_TF_DOCS -->
