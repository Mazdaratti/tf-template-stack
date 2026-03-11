# ECS Fargate Service Module

Reusable Terraform module to deploy **one ECS Fargate service** onto an existing ECS cluster.

This module is designed to be reusable outside this repository and intentionally keeps scope narrow:

- creates one ECS task definition
- creates one ECS service
- creates one task execution role
- creates one task role
- creates one service security group with standalone SG rule resources
- creates an optional CloudWatch Log Group for container logs
- supports optional attachment to an existing ALB target group
- applies consistent tagging across supported resources

---

## Use Cases

This module is useful when you need:

- the first real ECS workload layer after cluster/network/ingress baselines exist
- one reusable Fargate service per application or component
- private-subnet ECS deployment with module-managed security controls
- optional ALB integration without mixing ingress ownership into the service module
- service-level IAM, logging, and security group resources owned in one place

---

## Features (v1)

- One ECS Fargate service per module instance
- One typed single-container input model:
  - image, port, environment, secrets, command, entrypoint
  - optional container health check
- IAM model aligned with AWS best practice:
  - separate task execution role
  - separate task role
  - optional inline policy extension points
- Security group model aligned with current AWS provider best practice:
  - no inline SG rules
  - standalone ingress/egress rule resources
  - source-security-group-based ingress for least privilege
- Optional CloudWatch logging:
  - module-owned log group
  - configurable retention
  - optional KMS encryption
- Optional ALB integration:
  - attach to an existing target group ARN
  - keep ALB/listener/target group lifecycle outside the module
- Standard tagging model:
  - enforced: `Project`, `Environment`, `ManagedBy`
  - merged with `common_tags`

---

## Module Responsibilities

This module is responsible for:

- creating one ECS task definition
- creating one ECS service
- creating task execution and task IAM roles
- creating one service security group and standalone SG rules
- optionally creating one CloudWatch Log Group for container logs
- optionally attaching the service to an existing ALB target group
- exposing service, task, IAM, SG, and log outputs for downstream composition

This module is **not** responsible for:

- creating the ECS cluster
- creating ALB, listeners, or target groups
- Route53 record creation
- autoscaling policies
- service discovery
- blue/green or multi-pattern deployments
- multiple services or multiple primary containers per module instance

---

## Dependencies / Prerequisites

This module expects:

- AWS credentials configured for the target account and region
- an existing ECS cluster ARN
- an existing VPC and subnets for task placement
- when ALB integration is used:
  - an existing ALB target group ARN
  - one or more source security group IDs allowed to reach the service
- when KMS log encryption is used:
  - an existing KMS key ARN for CloudWatch Logs

In this repository architecture:

- `ecs_cluster` owns the ECS cluster foundation
- `alb_ingress` owns ALB, listeners, target groups, and ALB-side security groups
- `ecs_fargate_service` owns service-level compute, IAM, SG, and optional service log group resources

---

## Inputs Model

The module uses a baseline-first input model:

- required identity and tagging inputs (`project_name`, `environment`)
- required service wiring inputs (`cluster_arn`, `vpc_id`, `subnet_ids`)
- required task sizing inputs (`cpu`, `memory`)
- one typed `container` object instead of raw container-definition JSON
- optional logging controls for a module-managed CloudWatch Log Group
- optional ALB attachment object with minimal required fields
- explicit SG ingress model through `ingress_source_security_group_ids`

This keeps the module production-shaped and beginner-friendly without mixing in unrelated platform concerns.

---

## Design Notes

- v1 intentionally supports one primary container only.
- `assign_public_ip` defaults to `false` because private subnet placement is the recommended baseline.
- `load_balancer` is optional. When omitted, the service is deployed without ALB attachment.
- `health_check_grace_period_seconds` is only applied when a load balancer is configured.
- The module uses `target_type = "ip"` compatible attachment patterns for ECS/Fargate behind ALB.
- The execution role always includes the AWS-managed ECS task execution policy.

---

## Usage

Minimal example:

```hcl
module "ecs_fargate_service" {
  source = "..."

  project_name = "my-project"
  environment  = "dev"

  cluster_arn = "arn:aws:ecs:eu-central-1:123456789012:cluster/my-cluster"
  vpc_id      = "vpc-1234567890abcdef0"
  subnet_ids  = ["subnet-aaa", "subnet-bbb"]

  assign_public_ip = false
  desired_count    = 1

  cpu    = 256
  memory = 512

  container = {
    image = "public.ecr.aws/docker/library/nginx:stable"
    port  = 80
  }
}
```

---

## Examples

- `examples/basic_usage`
  - private-subnet ECS Fargate service baseline
  - no ALB attachment
  - includes NAT Gateway so private tasks can pull images and publish logs

- `examples/alb_integration`
  - internet-facing ALB in public subnets
  - ECS Fargate service in private subnets
  - target group attachment through `load_balancer`
  - SG-to-SG least-privilege traffic from ALB to service

Important:

- Both examples are runnable and create billable AWS resources.
- NAT Gateway is created in both examples and will incur cost while it exists.

---

## Notes

- Keep cluster lifecycle in `ecs_cluster`.
- Keep shared ingress lifecycle in `alb_ingress`.
- Keep DNS lifecycle outside this module unless explicitly needed in another layer.
- Log group outputs are `null` when `enable_cloudwatch_logging = false`.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.35.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_execution_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.task_execution_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.to_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_source_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.ecs_tasks_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether tasks receive public IPs. Recommended baseline is false for private subnet deployment. | `bool` | `false` | no |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ARN of the existing ECS cluster where the service will run. | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags to merge with enforced tags. | `map(string)` | `{}` | no |
| <a name="input_container"></a> [container](#input\_container) | Configuration for the single primary application container.<br/><br/>Fields:<br/>  - image (required): container image URI<br/>  - port (required): application port exposed by the container<br/>  - optional command / entrypoint<br/>  - optional environment variables<br/>  - optional secrets list for ECS valueFrom wiring<br/>  - optional container health check | <pre>object({<br/>    name        = optional(string)<br/>    image       = string<br/>    port        = number<br/>    essential   = optional(bool, true)<br/>    command     = optional(list(string))<br/>    entrypoint  = optional(list(string))<br/>    environment = optional(map(string), {})<br/>    secrets = optional(list(object({<br/>      name       = string<br/>      value_from = string<br/>    })), [])<br/>    readonly_root_filesystem = optional(bool, false)<br/>    health_check = optional(object({<br/>      command      = list(string)<br/>      interval     = optional(number)<br/>      timeout      = optional(number)<br/>      retries      = optional(number)<br/>      start_period = optional(number)<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Task-level CPU units for the Fargate task definition. | `number` | n/a | yes |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit on the number of running tasks during a deployment, as a percentage of desired\_count. | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit on the number of running tasks during a deployment, as a percentage of desired\_count. | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of task instances to run for the ECS service. | `number` | `1` | no |
| <a name="input_egress_cidr_ipv4"></a> [egress\_cidr\_ipv4](#input\_egress\_cidr\_ipv4) | List of IPv4 CIDRs allowed for outbound traffic from the service security group. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_enable_cloudwatch_logging"></a> [enable\_cloudwatch\_logging](#input\_enable\_cloudwatch\_logging) | Whether to configure the container to send logs to a module-managed CloudWatch Log Group. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming and tagging (e.g., dev, stage, prod). | `string` | n/a | yes |
| <a name="input_ephemeral_storage_gib"></a> [ephemeral\_storage\_gib](#input\_ephemeral\_storage\_gib) | Optional ephemeral storage size in GiB for the task definition. If null, AWS default is used. | `number` | `null` | no |
| <a name="input_execution_role_policy_json"></a> [execution\_role\_policy\_json](#input\_execution\_role\_policy\_json) | List of additional IAM policy JSON documents to attach inline to the task execution role. | `list(string)` | `[]` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Optional ECS service health check grace period in seconds.<br/><br/>This should be set only when the service is attached to a load balancer. | `number` | `null` | no |
| <a name="input_ingress_source_security_group_ids"></a> [ingress\_source\_security\_group\_ids](#input\_ingress\_source\_security\_group\_ids) | List of source security group IDs allowed to reach the service container port. | `list(string)` | `[]` | no |
| <a name="input_load_balancer"></a> [load\_balancer](#input\_load\_balancer) | Optional ALB target group attachment for the ECS service.<br/><br/>Fields:<br/>  - target\_group\_arn (required)<br/>  - container\_port (optional; defaults to container.port) | <pre>object({<br/>    target_group_arn = string<br/>    container_port   = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Optional CloudWatch Log Group name.<br/><br/>If null, the module uses:<br/>  "/<project\_name>/<environment>/ecs/<service\_name>" | `string` | `null` | no |
| <a name="input_log_kms_key_arn"></a> [log\_kms\_key\_arn](#input\_log\_kms\_key\_arn) | Optional KMS key ARN used to encrypt the module-managed CloudWatch Log Group. | `string` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Retention period in days for the module-managed CloudWatch Log Group. | `number` | `30` | no |
| <a name="input_log_stream_prefix"></a> [log\_stream\_prefix](#input\_log\_stream\_prefix) | Stream prefix used by the awslogs container log driver. | `string` | `"ecs"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Task-level memory (MiB) for the Fargate task definition. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Optional ECS service name.<br/><br/>If null, the module uses:<br/>  "<project\_name>-<environment>-ecs-service" | `string` | `null` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | Optional IAM permissions boundary ARN applied to the task execution role and task role. | `string` | `null` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | Fargate platform version for the ECS service. | `string` | `"LATEST"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming and tagging. | `string` | n/a | yes |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Whether ECS should propagate tags from the SERVICE or TASK\_DEFINITION. | `string` | `"SERVICE"` | no |
| <a name="input_runtime_platform"></a> [runtime\_platform](#input\_runtime\_platform) | Optional runtime platform override for the task definition.<br/><br/>Defaults:<br/>  operating\_system\_family = "LINUX"<br/>  cpu\_architecture        = "X86\_64" | <pre>object({<br/>    operating_system_family = optional(string)<br/>    cpu_architecture        = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Private subnet IDs where the ECS service tasks will be placed. | `list(string)` | n/a | yes |
| <a name="input_task_role_policy_json"></a> [task\_role\_policy\_json](#input\_task\_role\_policy\_json) | List of additional IAM policy JSON documents to attach inline to the task role. | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where service security group resources are created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group_arn"></a> [log\_group\_arn](#output\_log\_group\_arn) | ARN of the module-managed CloudWatch Log Group (null when logging is disabled). |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the module-managed CloudWatch Log Group (null when logging is disabled). |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID created for the ECS service. |
| <a name="output_service_arn"></a> [service\_arn](#output\_service\_arn) | ARN of the ECS service. |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID of the ECS service. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the ECS service. |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the ECS task definition. |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Family of the ECS task definition. |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | ARN of the ECS task execution role. |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | ARN of the ECS task role. |
<!-- END_TF_DOCS -->
