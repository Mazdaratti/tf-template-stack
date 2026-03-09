# ALB Ingress Module

Reusable Terraform module for creating an **Application Load Balancer (ALB) ingress baseline** for future service modules.

This module is designed to be reusable outside this repository and intentionally keeps scope narrow:

- creates one ALB
- creates ALB security group and standalone security group rules
- creates baseline listeners
- creates baseline target groups
- supports optional ALB access logs to S3
- applies consistent tagging across supported resources

---

## Use Cases

This module is useful when you need:

- a shared ingress layer before introducing ECS services
- an internal or internet-facing ALB baseline per environment
- reusable listener/target group outputs for downstream service modules
- optional ALB access logging integrated with an existing logs bucket

---

## Features (v1)

- One ALB per module instance:
  - `internal = true` for private ingress
  - `internal = false` for internet-facing ingress
- Security group model aligned with current AWS provider best practice:
  - no inline SG rules
  - standalone ingress/egress rule resources
  - supports CIDR-based and source-SG-based ingress
- Listener baseline:
  - map-driven listeners
  - HTTP protocol support in v1
  - default forward action to target groups
- Target group baseline:
  - map-driven target groups
  - `ip` target type in v1 (ECS/Fargate-friendly)
  - configurable health checks and common tuning knobs
- Optional access logs:
  - module can enable ALB access logs to S3
  - bucket policy ownership remains in the calling layer
- Standard tagging model:
  - enforced: `Project`, `Environment`, `ManagedBy`
  - merged with `common_tags`

---

## Module Responsibilities

This module is responsible for:

- creating one ALB
- creating ALB security group + standalone SG rules
- creating listeners and target groups
- exposing ALB/listener/target-group outputs for downstream modules

This module is **not** responsible for:

- ECS task definitions or ECS services
- listener rule orchestration (weighted/canary/advanced routing)
- Route53 record creation
- WAF integration
- ACM certificate lifecycle management

---

## Dependencies / Prerequisites

This module expects:

- AWS credentials configured for the target account and region
- an existing VPC and subnets for ALB placement
- ingress source model defined by caller (`ingress_cidr_ipv4` and/or `ingress_source_security_group_ids`)
- when access logs are enabled:
  - an existing S3 bucket must be provided
  - bucket policy must allow ALB log delivery (managed outside this module)

---

## Inputs Model

The module uses a baseline-first input model:

- required identity and tagging inputs (`project_name`, `environment`)
- required networking wiring (`vpc_id`, `subnet_ids`)
- optional ALB behavior controls (`name`, `internal`, timeout/deletion/header options)
- map-based listeners and target groups for predictable composition
- explicit SG ingress model for least-privilege access control
- optional access logs object for clean logging integration

This keeps ingress baseline reusable and production-shaped without mixing in service-layer concerns.

---

## Usage

Minimal example:

```hcl
module "alb_ingress" {
  source = "..."

  project_name = "my-project"
  environment  = "dev"

  vpc_id     = "vpc-1234567890abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  ingress_cidr_ipv4 = ["10.0.0.0/8"]

  target_groups = {
    app = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "app"
      }
    }
  }
}
```

---

## Examples

- `examples/basic_usage`
  - internal ALB baseline
  - HTTP listener + one IP target group
  - access logs disabled

- `examples/with_access_logs`
  - internal ALB baseline
  - ALB access logs enabled to S3
  - includes bucket policy example for ALB log delivery

- `examples/public_mode_minimal`
  - internet-facing ALB baseline
  - public subnet placement
  - ingress restricted to explicit CIDR ranges

- `examples/source_sg_ingress`
  - internal ALB baseline
  - ingress controlled by source security group IDs
  - demonstrates SG-to-SG least-privilege pattern

---

## Notes

- v1 intentionally supports HTTP listeners only.
- Listener default action is forward-to-target-group in v1.
- Keep service-level resources in dedicated service modules.
- Keep Route53 record management outside this module.

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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.to_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_cidr_by_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_sg_by_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Optional ALB access logging configuration.<br/><br/>- enabled: when true, ALB access logs are delivered to S3<br/>- bucket: destination S3 bucket name (required when enabled=true)<br/>- prefix: optional object key prefix | <pre>object({<br/>    enabled = bool<br/>    bucket  = optional(string)<br/>    prefix  = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags to merge with enforced tags. | `map(string)` | `{}` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Whether the ALB should drop invalid HTTP header fields. | `bool` | `true` | no |
| <a name="input_egress_cidr_ipv4"></a> [egress\_cidr\_ipv4](#input\_egress\_cidr\_ipv4) | List of IPv4 CIDRs allowed for ALB outbound traffic. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Whether deletion protection is enabled on the ALB. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming and tagging (e.g., dev, stage, prod). | `string` | n/a | yes |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | ALB idle timeout in seconds. | `number` | `60` | no |
| <a name="input_ingress_cidr_ipv4"></a> [ingress\_cidr\_ipv4](#input\_ingress\_cidr\_ipv4) | List of IPv4 CIDRs allowed to reach ALB listener ports. | `list(string)` | `[]` | no |
| <a name="input_ingress_source_security_group_ids"></a> [ingress\_source\_security\_group\_ids](#input\_ingress\_source\_security\_group\_ids) | List of source security group IDs allowed to reach ALB listener ports. | `list(string)` | `[]` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether the ALB is internal. If false, ALB is internet-facing. | `bool` | `true` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listeners to create.<br/><br/>Map key:<br/>  - Stable logical key used in Terraform state and outputs.<br/><br/>Value fields:<br/>  - port, protocol<br/>  - default\_action.type<br/>  - default\_action.target\_group\_key (must reference var.target\_groups key) | <pre>map(object({<br/>    port     = number<br/>    protocol = string<br/><br/>    default_action = object({<br/>      type             = string<br/>      target_group_key = string<br/>    })<br/>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Optional ALB name.<br/><br/>If null, the module uses:<br/>  "<project\_name>-<environment>-alb" | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming and tagging. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs where the ALB will be attached. At least two subnets in different Availability Zones are recommended. | `list(string)` | n/a | yes |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target groups to create.<br/><br/>Map key:<br/>  - Stable logical key used by listeners and outputs.<br/><br/>Value fields:<br/>  - port, protocol, target\_type<br/>  - optional health\_check<br/>  - optional target group tuning knobs | <pre>map(object({<br/>    port        = number<br/>    protocol    = string<br/>    target_type = string<br/><br/>    health_check = optional(object({<br/>      path                = optional(string, "/")<br/>      protocol            = optional(string, "HTTP")<br/>      matcher             = optional(string, "200-399")<br/>      interval            = optional(number, 30)<br/>      timeout             = optional(number, 5)<br/>      healthy_threshold   = optional(number, 3)<br/>      unhealthy_threshold = optional(number, 3)<br/>    }), {})<br/><br/>    deregistration_delay          = optional(number)<br/>    slow_start                    = optional(number)<br/>    load_balancing_algorithm_type = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where ALB and security group resources are created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the Application Load Balancer. |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer. |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | ID of the Application Load Balancer. |
| <a name="output_alb_name"></a> [alb\_name](#output\_alb\_name) | Name of the Application Load Balancer. |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Canonical hosted zone ID of the Application Load Balancer. |
| <a name="output_listener_arns"></a> [listener\_arns](#output\_listener\_arns) | Map of listener key => listener ARN. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID created for the Application Load Balancer. |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | Map of target group key => target group ARN. |
| <a name="output_target_group_names"></a> [target\_group\_names](#output\_target\_group\_names) | Map of target group key => target group name. |
<!-- END_TF_DOCS -->
