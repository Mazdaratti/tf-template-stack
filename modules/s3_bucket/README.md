# S3 Bucket Module

Reusable Terraform module to create a **secure-by-default S3 bucket**.

This module is generic by design:

- secure baseline configuration
- optional encryption customization (SSE-S3 or SSE-KMS)
- optional lifecycle rules
- optional access logging
- consistent tagging

---

## Use Cases

This module can be used for:

* Application data buckets
* Artifact storage (build artifacts, backups)
* ALB access logs bucket
* CloudTrail logs bucket
* General-purpose private storage
* Buckets requiring SSE-KMS encryption
* Buckets that require lifecycle-based cost optimization

---

## Features (v1)

* Create a single S3 bucket
* Secure baseline enforced:

  * Public access blocked
  * ACLs disabled (`BucketOwnerEnforced`)
  * TLS-only access policy (enabled by default)
  * Default encryption enabled
* Encryption options:

  * SSE-S3 (default)
  * SSE-KMS (AWS-managed or customer-managed key)
* Optional configuration:

  * `versioning_enabled`
  * `lifecycle_rules`
  * `access_logging`
  * `policy_json` override
* Consistent tagging:

  * `Project`, `Environment`, `ManagedBy` are enforced
  * additional `common_tags` are merged

---

## Dependencies / prerequisites

This module expects:

* AWS provider credentials configured for the target account/region

No additional AWS resources are required.

If using SSE-KMS with a customer-managed key, the KMS key must already exist.

---

## Encryption behavior (important)

By default, the module enables **SSE-S3 (AES256)** encryption.

If:

```hcl
encryption = {
  type = "KMS"
}
````

The bucket uses SSE-KMS with the AWS-managed S3 key.

If:

```hcl
encryption = {
  type        = "KMS"
  kms_key_arn = aws_kms_key.example.arn
}
```

The bucket uses a customer-managed KMS key.

> When using customer-managed KMS keys, ensure that the key policy allows S3 to use the key.

---

## Lifecycle behavior

Lifecycle rules are optional.

If no `lifecycle_rules` are provided:

* No lifecycle configuration is created.
* Objects remain in the bucket until manually deleted.

Rules may:

* Expire objects after X days
* Expire noncurrent versions after X days
* Abort incomplete multipart uploads

If no `prefix` or `tags` are defined in a rule, the rule applies to the **entire bucket**.

---

## Usage

### Basic usage

```hcl
module "s3_bucket" {
  source = "../../modules/s3_bucket"

  project_name = "my-project"
  environment  = "dev"

  bucket_name = "my-secure-bucket"

  versioning_enabled = true
}
```

---

### With lifecycle rules

```hcl
module "s3_bucket" {
  source = "../../modules/s3_bucket"

  project_name = "my-project"
  environment  = "dev"

  bucket_name = "my-secure-bucket"

  lifecycle_rules = [
    {
      id      = "expire-logs"
      enabled = true

      prefix          = "logs/"
      expiration_days = 30
    },
    {
      id      = "abort-multipart"
      enabled = true

      abort_incomplete_multipart_upload_days = 7
    }
  ]
}
```

---

### With SSE-KMS (customer-managed key)

```hcl
module "s3_bucket" {
  source = "../../modules/s3_bucket"

  project_name = "my-project"
  environment  = "dev"

  bucket_name = "my-secure-kms-bucket"

  encryption = {
    type        = "KMS"
    kms_key_arn = aws_kms_key.example.arn
  }
}
```

---

## Examples

This module includes runnable examples demonstrating real usage patterns:

### basic_usage

Demonstrates:

* secure-by-default S3 bucket
* versioning enabled
* lifecycle rules:

  * object expiration
  * noncurrent version expiration
  * multipart upload cleanup

### kms_usage

Demonstrates:

* creating a KMS key inside the example
* using SSE-KMS encryption
* versioning enabled

All examples are designed to be:

* runnable independently
* minimal but realistic
* consistent with this repo’s style

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.32.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logging"></a> [access\_logging](#input\_access\_logging) | Server access logging configuration (optional).<br/><br/>If enabled = true, you must provide target\_bucket.<br/>target\_prefix is optional and helps separate logs by application/team. | <pre>object({<br/>    enabled       = bool<br/>    target_bucket = optional(string)<br/>    target_prefix = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "target_bucket": null,<br/>  "target_prefix": null<br/>}</pre> | no |
| <a name="input_attach_deny_insecure_transport_policy"></a> [attach\_deny\_insecure\_transport\_policy](#input\_attach\_deny\_insecure\_transport\_policy) | If true, attach a baseline bucket policy that denies any request over insecure transport (non-TLS). | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The S3 bucket name. Must be globally unique. | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | A map of common tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Default encryption configuration for the bucket.<br/><br/>type:<br/>  - "S3"  => SSE-S3 (AES256)<br/>  - "KMS" => SSE-KMS (AWS-managed key by default, or a customer-managed key if kms\_key\_arn is provided)<br/><br/>kms\_key\_arn:<br/>  - Optional. Only used when type == "KMS".<br/>  - Pass a key ARN from the kms\_keys module to use a customer-managed key. | <pre>object({<br/>    type        = string<br/>    kms_key_arn = optional(string)<br/>  })</pre> | <pre>{<br/>  "kms_key_arn": null,<br/>  "type": "S3"<br/>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming/tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | If true, Terraform can delete the bucket even if it contains objects. Keep false for production by default. | `bool` | `false` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Optional lifecycle rules for the bucket.<br/><br/>Supported (minimal, production-grade):<br/>- expiration\_days (current objects)<br/>- noncurrent\_version\_expiration\_days (older versions)<br/>- abort\_incomplete\_multipart\_upload\_days (cleanup)<br/><br/>Scope (optional):<br/>- prefix<br/>- tags<br/>If neither prefix nor tags are set, the rule applies to the whole bucket. | <pre>list(object({<br/>    id      = string<br/>    enabled = bool<br/><br/>    prefix = optional(string)<br/>    tags   = optional(map(string))<br/><br/>    expiration_days                        = optional(number)<br/>    noncurrent_version_expiration_days     = optional(number)<br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Optional bucket policy JSON to attach (combined with baseline TLS-only policy unless disabled). | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable S3 versioning. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the S3 bucket. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name (useful for some integrations). |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The ID of the S3 bucket (same as the bucket name for S3). |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | The name of the S3 bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The regional bucket domain name (recommended for region-specific endpoints). |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The Route 53 Hosted Zone ID for this bucket's region. |
<!-- END_TF_DOCS -->