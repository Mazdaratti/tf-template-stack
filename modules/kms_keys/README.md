# KMS Keys Module

Reusable Terraform module to create one or more **AWS KMS keys** with aliases.

This module is generic by design:
- safe defaults (prevents lockout)
- optional per-key policy override
- consistent tagging

---

## Features (v1)

* Create multiple KMS keys using a map input (`keys`)
* Create exactly one alias per key
* Per-key configuration support:
  * `enable_key_rotation`
  * `deletion_window_in_days`
  * `is_enabled`
  * `multi_region`
  * `alias_name` override
  * per-key `tags`
  * optional `policy` override (JSON)
* Safe default key policy when `policy` is omitted
* Consistent tagging:
  * `Project`, `Environment`, `ManagedBy` are enforced
  * additional `common_tags` are merged
  * per-key tags are supported

---

## Dependencies / prerequisites

This module expects:

* AWS provider credentials configured for the target account/region

No additional AWS resources are required.

---

## Key policy behavior (important)

If no `policy` is provided for a key, the module applies a **safe default policy**:

* Grants full `kms:*` permissions to the AWS account root principal for the current account.
* Prevents accidental lockout.
* Keeps the module reusable and not service-specific.

In real-world production environments, you typically:

* Keep the root/admin statement
* Add additional statements delegating usage or admin rights to specific IAM roles


Custom policies must be built in the calling layer using `aws_iam_policy_document`
and passed via:

```hcl
policy = data.aws_iam_policy_document.example.json
```

⚠️ KMS key policies are security-critical. Misconfiguration can lock you out of the key.

---

## Usage

### Basic usage

```hcl
module "kms_keys" {
  source = "../../modules/kms_keys"

  project_name = "my-project"
  environment  = "dev"

  keys = {
    logs = {
      description         = "KMS key for log encryption"
      enable_key_rotation = true
    }

    s3 = {
      description         = "KMS key for S3 bucket encryption"
      enable_key_rotation = true
    }
  }

  common_tags = {
    Team = "Platform"
  }
}
````

---

### With custom key policy (advanced)

Build the policy in the calling layer and pass it into the module.

```hcl
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "kms_logs" {
  # Recommended: always keep an admin/root statement to prevent lockout
  statement {
    sid    = "AllowAccountRootFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Example usage delegation (replace role ARN in real projects)
  # statement {
  #   sid    = "AllowKeyUsageForRole"
  #   effect = "Allow"
  #
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::123456789012:role/example-role"]
  #   }
  #
  #   actions = [
  #     "kms:Encrypt",
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey",
  #     "kms:DescribeKey"
  #   ]
  #
  #   resources = ["*"]
  # }
}

module "kms_keys" {
  source = "../../modules/kms_keys"

  project_name = "my-project"
  environment  = "dev"

  keys = {
    logs = {
      description = "KMS key for logs"
      policy      = data.aws_iam_policy_document.kms_logs.json
    }
  }
}
```

> If `policy` is omitted for a key, the module applies the default key policy.

---

## Examples

This module includes runnable examples demonstrating real usage patterns:

### basic_usage

Demonstrates:

* creating multiple keys from a map input
* using module default key policy
* automatic alias generation

### custom_policy

Demonstrates:

* overriding policy for one key
* showing all optional arguments (commented) with default values

All examples are designed to be:

* runnable independently
* minimal but realistic
* consistent with this repo’s style

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tagging and default naming (e.g., dev, stage, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for tagging and default naming. | `string` | n/a | yes |
| <a name="input_alias_prefix"></a> [alias\_prefix](#input\_alias\_prefix) | Optional prefix for KMS aliases. If null, defaults to '<project\_name>-<environment>'. | `string` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags to merge with enforced tags. | `map(string)` | `{}` | no |
| <a name="input_keys"></a> [keys](#input\_keys) | Map of KMS keys to create.<br/><br/>Each key object supports:<br/>- description (optional)<br/>- enable\_key\_rotation (optional, default true)<br/>- deletion\_window\_in\_days (optional, default 30; valid range 7..30)<br/>- policy (optional JSON string; if null, module default policy is used)<br/>- is\_enabled (optional, default true)<br/>- multi\_region (optional, default false)<br/>- alias\_name (optional; full alias name like 'alias/my-key')<br/>- tags (optional; per-key tags merged with module tags) | <pre>map(object({<br/>    description             = optional(string)<br/>    enable_key_rotation     = optional(bool, true)<br/>    deletion_window_in_days = optional(number, 30)<br/>    policy                  = optional(string)<br/>    is_enabled              = optional(bool, true)<br/>    multi_region            = optional(bool, false)<br/>    alias_name              = optional(string)<br/>    tags                    = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alias_names"></a> [alias\_names](#output\_alias\_names) | Map of key name => KMS alias name. |
| <a name="output_key_arns"></a> [key\_arns](#output\_key\_arns) | Map of key name => KMS key ARN. |
| <a name="output_key_ids"></a> [key\_ids](#output\_key\_ids) | Map of key name => KMS key ID. |
| <a name="output_keys"></a> [keys](#output\_keys) | Map of key name => object with key\_arn, key\_id, and alias\_name. |
<!-- END_TF_DOCS -->