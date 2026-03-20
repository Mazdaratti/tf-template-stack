# ECS Cluster Module

Reusable Terraform module to create and manage an **ECS cluster** with optional cluster-level settings.

This module is designed to be reusable outside this repository and intentionally keeps scope narrow:

- creates one ECS cluster
- configures optional Container Insights
- configures capacity providers and optional default strategy
- configures optional ECS Exec behavior
- applies consistent tagging across supported resources

---

## Use Cases

This module is useful when you need:

- a baseline ECS cluster per environment (`dev`, `staging`, `prod`)
- consistent cluster configuration before adding service modules
- predictable capacity provider behavior across environments
- optional ECS Exec configuration with explicit controls

---

## Features (v1)

- ECS cluster creation with stable naming
- Optional Container Insights toggle
- Capacity provider support:
  - baseline providers (`FARGATE`, `FARGATE_SPOT`)
  - optional default capacity provider strategy
- Optional ECS Exec configuration:
  - `DEFAULT`
  - `OVERRIDE` (with required CloudWatch log group name)
  - `NONE`
- Standard tagging model:
  - enforced: `Project`, `Environment`, `ManagedBy`
  - merged with `common_tags`

---

## Module Responsibilities

This module is responsible for:

- creating one ECS cluster
- applying optional cluster-level configuration
- associating capacity providers
- exposing cluster outputs for downstream modules

This module is **not** responsible for:

- task definitions
- ECS services or service autoscaling
- ALB or target group resources
- VPC/subnet/security group resources
- application logging pipelines

---

## Dependencies / Prerequisites

This module expects:

- AWS credentials configured for the target account and region
- AWS ECS service enabled in the target account/region
- an execution context with permissions to:
  - create and manage ECS clusters
  - associate ECS cluster capacity providers
- when ECS Exec override logging is enabled:
  - an existing CloudWatch Log Group name must be provided via `exec_cloudwatch_log_group_name`

In this repository architecture, shared logging resources are typically created by dedicated logging modules and passed into compute modules as inputs.

---

## Inputs Model

The module uses a baseline-first input model:

- required identity and tagging inputs (`project_name`, `environment`)
- optional cluster name override (`cluster_name`)
- optional observability control (`enable_container_insights`)
- optional capacity provider strategy (`default_capacity_provider_strategy`)
- optional ECS Exec configuration with validation for `OVERRIDE`

This keeps the module production-usable without mixing in service-level concerns.

---

## Usage

Minimal example:

```hcl
module "ecs_cluster" {
  source = "..."

  project_name = "my-project"
  environment  = "dev"
}
```

---

## Examples

- `examples/basic_usage`
  - creates a minimal ECS cluster baseline
  - demonstrates default-friendly usage with cluster outputs
  - does not enable advanced ECS Exec override behavior

- `examples/advanced_usage`
  - demonstrates explicit capacity provider strategy
  - enables ECS Exec with `OVERRIDE` logging mode
  - creates a dedicated CloudWatch log group for exec logs in the example scope

---

## Notes

- `default_capacity_provider_strategy` output is `null` when not configured.
- `exec_cloudwatch_log_group_name` is required only when:
  - `exec_enabled = true`
  - `exec_logging = "OVERRIDE"`
- Keep service-level resources in dedicated service modules.

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
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tagging and naming (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for tagging and naming. | `string` | n/a | yes |
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | Set of capacity providers to associate with the cluster.<br/><br/>Recommended baseline:<br/>  ["FARGATE", "FARGATE\_SPOT"] | `set(string)` | <pre>[<br/>  "FARGATE",<br/>  "FARGATE_SPOT"<br/>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Optional ECS cluster name.<br/><br/>If null, the module uses:<br/>  "<project\_name>-<environment>-ecs-cluster" | `string` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags applied to all resources. Enforced tags are merged in the module. | `map(string)` | `{}` | no |
| <a name="input_default_capacity_provider_strategy"></a> [default\_capacity\_provider\_strategy](#input\_default\_capacity\_provider\_strategy) | Optional default capacity provider strategy applied at the cluster level.<br/><br/>Each object:<br/>  - capacity\_provider (string, required)<br/>  - weight (number, required, >= 0)<br/>  - base (number, optional, >= 0)<br/><br/>Rules:<br/>  - capacity\_provider must exist in var.capacity\_providers<br/>  - list must be non-empty when set (non-null) | <pre>list(object({<br/>    capacity_provider = string<br/>    weight            = number<br/>    base              = optional(number)<br/>  }))</pre> | `null` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Whether to enable ECS Container Insights at the cluster level. | `bool` | `true` | no |
| <a name="input_exec_cloudwatch_log_group_name"></a> [exec\_cloudwatch\_log\_group\_name](#input\_exec\_cloudwatch\_log\_group\_name) | CloudWatch Log Group name used for ECS Exec logs when exec\_logging = "OVERRIDE".<br/><br/>Required only when:<br/>  exec\_enabled = true AND exec\_logging = "OVERRIDE" | `string` | `null` | no |
| <a name="input_exec_enabled"></a> [exec\_enabled](#input\_exec\_enabled) | Whether to enable ECS Exec configuration at the cluster level. | `bool` | `false` | no |
| <a name="input_exec_logging"></a> [exec\_logging](#input\_exec\_logging) | ECS Exec logging mode.<br/><br/>Allowed values:<br/>  - DEFAULT<br/>  - OVERRIDE (requires exec\_cloudwatch\_log\_group\_name)<br/>  - NONE | `string` | `"DEFAULT"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_capacity_providers"></a> [capacity\_providers](#output\_capacity\_providers) | Set of capacity providers associated with the ECS cluster. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the ECS cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the ECS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the ECS cluster. |
| <a name="output_default_capacity_provider_strategy"></a> [default\_capacity\_provider\_strategy](#output\_default\_capacity\_provider\_strategy) | Default capacity provider strategy configured for the ECS cluster (null if not configured). |
<!-- END_TF_DOCS -->
