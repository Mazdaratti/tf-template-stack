# VPC Interface Endpoints Module (PrivateLink)

Reusable Terraform module to create **Interface VPC Endpoints** (AWS PrivateLink) for AWS services such as:

* **SSM** (`ssm`, `ec2messages`, `ssmmessages`)
* **CloudWatch Logs** (`logs`)
* **Secrets Manager** (`secretsmanager`)

Interface endpoints create **ENIs in subnets** and are controlled by **security groups**.

---

## Features (v1)

* Create one or more interface VPC endpoints (configurable per service)
* Place endpoints into one or more subnets (`subnet_ids`)
* Optional security group handling:

  * **Module-managed SG** when `create_security_group = true`
  * Or **externally managed SGs** via `security_group_ids`
* Optional endpoint policies per service:

  * Provide JSON via `endpoint_policy_json` (`map(service => json)`)
  * If omitted for a service, AWS uses the **default** endpoint policy
* Per-endpoint control:

  * `private_dns_enabled` (defaults to `true`)
* Consistent tagging:

  * `Project`, `Environment`, `ManagedBy` are enforced
  * additional `common_tags` are merged

---

## Dependencies / prerequisites

This module expects these resources to already exist:

* **VPC** (`vpc_id`)
* **Subnets** (`subnet_ids`)

  * Typically **private subnets** across 2+ AZs for HA

### Security groups (important)

Interface endpoints require at least one security group.

You must choose one of these patterns:

* **A) Module-managed SG**

  * Set `create_security_group = true`
  * Module creates SG + baseline rules (managed as separate SG rule resources)

* **B) External SGs (recommended for real platforms)**

  * Set `create_security_group = false`
  * Provide at least one SG ID via `security_group_ids`

This module enforces that either `create_security_group = true` or `security_group_ids` is non-empty.

---

## Conceptual difference vs Gateway Endpoints

| Gateway endpoints            | Interface endpoints            |
| ---------------------------- | ------------------------------ |
| Attached to **route tables** | Placed into **subnets** (ENIs) |
| No security groups           | **Require security groups**    |
| Only S3 + DynamoDB           | Most AWS services              |
| Routing-based                | ENI + DNS-based                |

---

## Usage

### Basic (SSM baseline)

```hcl
module "vpc_interface_endpoints" {
  source = "../../modules/vpc_interface_endpoints"

  project_name = "my-project"
  environment  = "dev"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  # Module-managed SG (required unless you pass security_group_ids)
  create_security_group = true

  interface_endpoints = {
    ssm = {
      enabled = true
    }
    ec2messages = {
      enabled = true
    }
    ssmmessages = {
      enabled = true
    }
  }

  common_tags = {
    Team = "Platform"
  }
}
```

---

### Platform baseline (external/shared SG)

```hcl
module "vpc_interface_endpoints" {
  source = "../../modules/vpc_interface_endpoints"

  project_name = "my-project"
  environment  = "dev"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  # External SG pattern
  create_security_group = false
  security_group_ids    = [aws_security_group.vpce_shared.id]

  interface_endpoints = {
    ssm            = { enabled = true }
    ec2messages    = { enabled = true }
    ssmmessages    = { enabled = true }
    logs           = { enabled = true }
    secretsmanager = { enabled = true }
  }
}
```

---

### With endpoint policies (advanced pattern)

Build policies in the calling layer using `aws_iam_policy_document`
and pass `.json` into the module.

```hcl
data "aws_iam_policy_document" "vpce_secretsmanager" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      module.secrets.secret_arn
    ]
  }
}

module "vpc_interface_endpoints" {
  source = "../../modules/vpc_interface_endpoints"

  project_name = "my-project"
  environment  = "dev"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  create_security_group = false
  security_group_ids    = [aws_security_group.vpce_shared.id]

  interface_endpoints = {
    secretsmanager = { enabled = true }
  }

  endpoint_policy_json = {
    secretsmanager = data.aws_iam_policy_document.vpce_secretsmanager.json
  }
}
```

> If no policy is provided for a service, AWS applies the **default endpoint policy** for that endpoint.

---

## Examples

This module includes runnable examples demonstrating real usage patterns:

### ssm_minimal

Demonstrates:

* minimal VPC + private subnets (standalone)
* SSM-required endpoints:

  * `ssm`, `ec2messages`, `ssmmessages`
* module-managed security group (`create_security_group = true`)

### platform_baseline

Demonstrates:

* minimal VPC + private subnets (standalone)
* external/shared SG pattern (`security_group_ids` passed in)
* enabling a broader baseline set:

  * SSM trio + `logs` + `secretsmanager`

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
| [aws_security_group.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g. dev, stage, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming and tagging. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs (typically private subnets) for interface endpoints. | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where interface endpoints will be created. | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a minimal security group for the interface endpoints. | `bool` | `false` | no |
| <a name="input_endpoint_policy_json"></a> [endpoint\_policy\_json](#input\_endpoint\_policy\_json) | Optional map of service => policy JSON to attach to interface endpoints.<br/><br/>Policies are usually defined in envs/<env>/endpoint\_policies.tf<br/>and passed into this module.<br/><br/>If a service key is omitted, AWS default endpoint policy is used. | `map(string)` | `{}` | no |
| <a name="input_interface_endpoints"></a> [interface\_endpoints](#input\_interface\_endpoints) | Map of interface endpoints to create.<br/><br/>Key   = service identifier (e.g. ssm, ec2messages, logs)<br/>Value = object with enable flag and optional private DNS control.<br/><br/>Example:<br/>{<br/>  ssm = {<br/>    enabled             = true<br/>    private\_dns\_enabled = true<br/>  }<br/>} | <pre>map(object({<br/>    enabled             = bool<br/>    private_dns_enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Existing security group IDs to attach to interface endpoints. Preferred in real-world setups. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_entries"></a> [dns\_entries](#output\_dns\_entries) | Map of service => list of DNS entries for the interface endpoint. |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | Set of enabled interface endpoint service keys. |
| <a name="output_endpoint_arns"></a> [endpoint\_arns](#output\_endpoint\_arns) | Map of service => interface VPC endpoint ARN. |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | Map of service => interface VPC endpoint ID. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID created by this module (null if not created). Use this to add extra rules from envs/*. |
<!-- END_TF_DOCS -->

---


