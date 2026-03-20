# Logging Baseline Module

Reusable Terraform module to create a **controlled set of shared CloudWatch Log Groups**.

This module is generic by design:

- creates only explicitly defined log groups (no automatic factory behavior)
- consistent naming via configurable prefix
- baseline retention with per-log-group override
- optional KMS encryption (module-level + per-log-group override)
- consistent tagging across all resources

---

## Use Cases

This module can be used for:

* Shared VPC Flow Logs destination (for the upcoming `vpc_flow_logs` module)
* Shared application log groups
* Centralized audit log groups
* Platform-level logging primitives
* Any environment requiring standardized CloudWatch Log Groups

---

## Features (v1)

* Create multiple CloudWatch Log Groups via `log_groups` map
* Naming pattern:

```

<log_group_name_prefix>/<name_suffix>

```

* Default retention (30 days by default)
* Per-log-group retention override
* Optional encryption:

* Module-level `kms_key_arn`
* Per-log-group `kms_key_arn` override
* Consistent tagging:

* `Project`, `Environment`, `ManagedBy` are enforced
* additional `common_tags` are merged

---

## Dependencies / prerequisites

This module expects:

* AWS provider credentials configured for the target account/region

No additional AWS resources are required.

If using KMS encryption, the KMS key must already exist.

In this repository, KMS keys are created by the `kms_keys` module and passed into this module.

---

## Naming behavior (important)

Log group names are constructed as:

```

<log_group_name_prefix>/<name_suffix>

````

Example:

```hcl
log_group_name_prefix = "/my-project/dev"
name_suffix           = "vpc-flow-logs"
````

Final name:

```
/my-project/dev/vpc-flow-logs
```

To avoid accidental double slashes, the module automatically trims a trailing `/` from `log_group_name_prefix`.

---

## Retention behavior

The module applies:

* `retention_in_days` (default = 30)

Unless overridden per log group:

```hcl
log_groups = {
  app_logs = {
    name_suffix       = "app-logs"
    retention_in_days = 14
  }
}
```

If no override is provided, the module default retention is used.

---

## Encryption behavior (important)

Encryption resolution order for each log group:

1. `log_groups[KEY].kms_key_arn` (per-log-group override)
2. `kms_key_arn` (module-level default)
3. `null` (no encryption)

Example:

```hcl
kms_key_arn = aws_kms_key.logs_default.arn

log_groups = {
  audit_logs = {
    name_suffix = "audit-logs"
  }

  secure_logs = {
    name_suffix = "secure-logs"
    kms_key_arn = aws_kms_key.logs_override.arn
  }
}
```

> When using customer-managed KMS keys, ensure the key policy allows CloudWatch Logs to use the key.

---

## Usage

### Basic usage

```hcl
module "logging_baseline" {
  source = "../../modules/logging_baseline"

  project_name = "my-project"
  environment  = "dev"

  log_group_name_prefix = "/my-project/dev"

  retention_in_days = 30

  log_groups = {
    vpc_flow_logs = {
      name_suffix = "vpc-flow-logs"
    }
  }
}
```

---

### With KMS encryption

```hcl
module "logging_baseline" {
  source = "../../modules/logging_baseline"

  project_name = "my-project"
  environment  = "dev"

  log_group_name_prefix = "/my-project/dev"

  kms_key_arn = aws_kms_key.logs_default.arn

  log_groups = {
    vpc_flow_logs = {
      name_suffix = "vpc-flow-logs"
    }

    audit_logs = {
      name_suffix = "audit-logs"
      kms_key_arn = aws_kms_key.logs_override.arn
    }
  }
}
```

---

## Examples

This module includes runnable examples demonstrating real usage patterns:

### basic_usage

Demonstrates:

* Creating multiple shared log groups
* Default retention
* Per-log-group retention override
* Standardized naming

### kms_usage

Demonstrates:

* Creating KMS keys inside the example
* Module-level KMS encryption
* Per-log-group KMS override

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
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_log_group_name_prefix"></a> [log\_group\_name\_prefix](#input\_log\_group\_name\_prefix) | Prefix used to construct CloudWatch Log Group names.<br/><br/>The module creates names in the form:<br/>  <log\_group\_name\_prefix>/<name\_suffix><br/><br/>Recommended env/dev pattern:<br/>  "/<project\_name>/<environment>"<br/><br/>Note: the module will trim a trailing "/" from this value to avoid "//" in names. | `string` | n/a | yes |
| <a name="input_log_groups"></a> [log\_groups](#input\_log\_groups) | Map of CloudWatch Log Groups to create.<br/><br/>Map key:<br/>  - Stable identifier used in Terraform state and module outputs.<br/>  - Does NOT affect the log group name.<br/><br/>Value fields:<br/>  - name\_suffix (required): appended to the prefix to form the full log group name<br/>  - retention\_in\_days (optional): override default retention for this log group<br/>  - kms\_key\_arn (optional): override default KMS key for this log group | <pre>map(object({<br/>    name_suffix       = string<br/>    retention_in_days = optional(number)<br/>    kms_key_arn       = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for tagging. | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | A map of common tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional default KMS key ARN used to encrypt CloudWatch Log Groups.<br/><br/>Resolution order for each log group:<br/>1) var.log\_groups[KEY].kms\_key\_arn (per-log-group override)<br/>2) var.kms\_key\_arn (module-level default)<br/>3) null (no KMS encryption) | `string` | `null` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Default retention period (in days) for log groups, unless overridden per log group. | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group_arns"></a> [log\_group\_arns](#output\_log\_group\_arns) | Map of log group ARNs created by this module (keyed by log\_groups map keys). |
| <a name="output_log_group_names"></a> [log\_group\_names](#output\_log\_group\_names) | Map of log group names created by this module (keyed by log\_groups map keys). |
<!-- END_TF_DOCS -->