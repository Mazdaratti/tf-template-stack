# VPC Flow Logs Module

Reusable Terraform module to enable **VPC Flow Logs** for a single VPC and publish records to an **existing CloudWatch Log Group**.

This module is generic by design:

- enables Flow Logs for exactly one VPC (no factory behavior)
- does **not** create the CloudWatch Log Group (destination is provided)
- creates the IAM role and minimal inline policy required for delivery
- configurable traffic type (ALL / ACCEPT / REJECT)
- configurable aggregation interval (60 / 600)
- consistent tagging across all resources

---

## Use Cases

This module can be used for:

* Enabling VPC Flow Logs in any environment (dev / staging / prod)
* Centralizing VPC Flow Logs into a shared CloudWatch Log Group
* Standardizing Flow Logs configuration across multiple VPCs
* Providing baseline network visibility for security investigations
* Supporting compliance requirements for network traffic auditing

Each VPC should instantiate this module separately.

---

## Features (v1)

* Enable Flow Logs for a single VPC
* Publish logs to CloudWatch Logs using:
  * `log_destination_type = "cloud-watch-logs"`
  * `log_destination      = var.log_group_arn`
* Traffic type configuration:
  * `ALL` (default)
  * `ACCEPT`
  * `REJECT`
* Aggregation interval:
  * default: `600`
  * allowed values: `60` or `600`
* IAM role:
  * service principal: `vpc-flow-logs.amazonaws.com`
  * minimal required CloudWatch permissions
  * confused deputy protection enforced
  * optional permissions boundary support
* Standardized tagging model:
  * enforced tags: `Project`, `Environment`, `ManagedBy`
  * merged with `common_tags`
  * resource-specific `Name` tags added per resource

---

## Module Responsibilities

This module is responsible for:

* Creating the IAM role required for VPC Flow Logs delivery
* Creating the inline IAM policy granting CloudWatch Logs write permissions
* Creating the `aws_flow_log` resource for the specified VPC
* Applying standardized repository tagging

This module is **not** responsible for:

* Creating CloudWatch Log Groups
* Managing KMS keys
* Creating S3-based Flow Logs destinations
* Creating subscription filters or analytics pipelines
* Managing multiple VPCs in a single module instance

---

## Dependencies / Prerequisites

This module expects:

* AWS credentials configured for the target account and region
* An existing CloudWatch Log Group (provided via `log_group_arn`)
* A valid VPC ID (`vpc_id`)

In this repository architecture, the CloudWatch Log Group is created by the `logging_baseline` module and its ARN is passed into this module.

---

## IAM Design (Important)

The IAM role created by this module:

* Is assumed by `vpc-flow-logs.amazonaws.com`
* Restricts trust using:
  * `aws:SourceAccount`
  * `aws:SourceArn`
* Grants only the minimum permissions required:
  * `logs:CreateLogStream`
  * `logs:PutLogEvents`
  * `logs:DescribeLogStreams`
  * `logs:DescribeLogGroups`

If the destination Log Group is KMS-encrypted, encryption handling is managed by the Log Group and its associated KMS key policy — not by this module.

---

## Usage

Minimal usage example:

```hcl
module "vpc_flow_logs" {
  source = "..."

  project_name = "my-project"
  environment  = "dev"

  common_tags = {
    Owner = "network-team"
  }

  vpc_id        = aws_vpc.this.id
  log_group_arn = module.logging_baseline.log_group_arns["vpc_flow_logs"]
}
````

Optional arguments:

```hcl
traffic_type             = "REJECT"  # Default: "ALL"
max_aggregation_interval = 60        # Default: 600
permissions_boundary_arn = "arn:aws:iam::123456789012:policy/boundary"
```

---

## Examples

See the runnable example:

```
examples/basic_usage
```

The example demonstrates:

* Creating a minimal VPC
* Creating a CloudWatch Log Group (for demonstration purposes only)
* Enabling VPC Flow Logs using this module
* Retrieving useful outputs

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_to_cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags to merge with enforced tags. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_log_group_arn"></a> [log\_group\_arn](#input\_log\_group\_arn) | ARN of an existing CloudWatch Log Group to receive VPC Flow Logs (owned outside this module). | `string` | n/a | yes |
| <a name="input_max_aggregation_interval"></a> [max\_aggregation\_interval](#input\_max\_aggregation\_interval) | Maximum aggregation interval in seconds. Valid values: 60 or 600. If null, AWS default is used. | `number` | `600` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | Optional IAM permissions boundary ARN to attach to the Flow Logs IAM role. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for tagging. | `string` | n/a | yes |
| <a name="input_traffic_type"></a> [traffic\_type](#input\_traffic\_type) | Traffic type to log. Valid values: ALL, ACCEPT, REJECT. | `string` | `"ALL"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC to enable Flow Logs for. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | ID of the VPC Flow Log. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role used by VPC Flow Logs. |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role used by VPC Flow Logs. |
<!-- END_TF_DOCS -->
