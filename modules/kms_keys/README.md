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

<!-- END_TF_DOCS -->

---