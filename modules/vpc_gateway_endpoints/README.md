# VPC Gateway Endpoints Module (S3, DynamoDB)

Reusable Terraform module to create **Gateway VPC Endpoints** for AWS:
- **S3** (`com.amazonaws.<region>.s3`)
- **DynamoDB** (`com.amazonaws.<region>.dynamodb`)

Gateway endpoints attach to **route tables** and add AWS-managed prefix list routes automatically.

## Features (v1)

- Create S3 and/or DynamoDB gateway endpoints (configurable)
- Attach endpoints to one or more route tables (`route_table_ids`)
- Optional endpoint policies per service:
  - Provide JSON via `endpoint_policy_json`
  - Policies are applied via `aws_vpc_endpoint_policy` only when explicitly provided
- Consistent tagging:
  - `Project`, `Environment`, `ManagedBy` are enforced
  - additional `common_tags` are merged

---

## Dependencies / prerequisites

This module expects the following underlying resources to already exist:

- **VPC** (`vpc_id`)
- **Route tables** (`route_table_ids`)
  - Typically private route tables (so private subnets can reach S3/DynamoDB without NAT)

> AWS constraint: a single route table cannot have multiple gateway endpoint routes to the same service (e.g., two S3 gateway endpoints attached to the same route table). Keep route table association unique per service.

---

## Usage

### Basic (no custom policies)

```hcl
module "vpc_gateway_endpoints" {
  source = "../../modules/vpc_gateway_endpoints"

  project_name = "my-project"
  environment  = "dev"

  vpc_id = module.network.vpc_id

  # Attach to private route tables (recommended)
  route_table_ids = values(module.network.private_route_table_ids_by_az)

  gateway_endpoints = {
    s3       = true
    dynamodb = true
  }

  common_tags = {
    Team = "Platform"
  }
}
```

### With endpoint policies (recommended pattern)

Build policies in the calling layer using `aws_iam_policy_document`
and pass `.json` into the module.

```hcl
data "aws_iam_policy_document" "vpce_s3" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      module.storage.bucket_arn,
      "${module.storage.bucket_arn}/*"
    ]
  }
}

module "vpc_gateway_endpoints" {
  source = "../../modules/vpc_gateway_endpoints"

  project_name = "my-project"
  environment  = "dev"

  vpc_id          = module.network.vpc_id
  route_table_ids = values(module.network.private_route_table_ids_by_az)

  gateway_endpoints = {
    s3       = true
    dynamodb = false
  }

  endpoint_policy_json = {
    s3 = data.aws_iam_policy_document.vpce_s3.json
  }
}
```

---

## Examples

This module includes runnable examples demonstrating typical usage patterns.

### basic_usage
Minimal example showing how to:

- create a VPC
- create a route table
- attach S3 and DynamoDB gateway endpoints
- use module defaults without custom policies

Use this example to verify module behavior quickly.

---

### with_policies
Demonstrates how to:

- create endpoint policies using `aws_iam_policy_document`
- inject policy JSON into the module via `endpoint_policy_json`
- reference resources dynamically (S3 bucket, DynamoDB table)

This example intentionally creates local resources for demonstration.
In real projects, policies typically reference resources created in other modules, for example:

- `module.storage.bucket_arn`
- `module.database.table_arn`

---

All examples are designed to be:

- runnable independently
- easy to understand
- representative of real-world usage


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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_policy.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_policy) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_endpoint_policy_json"></a> [endpoint\_policy\_json](#input\_endpoint\_policy\_json) | Optional map of service => policy JSON (keys: s3, dynamodb). If omitted for a service, AWS default policy is used. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming/tagging (e.g., dev, stage, prod). | `string` | n/a | yes |
| <a name="input_gateway_endpoints"></a> [gateway\_endpoints](#input\_gateway\_endpoints) | Which gateway endpoints to create. | <pre>object({<br/>    s3       = bool<br/>    dynamodb = bool<br/>  })</pre> | <pre>{<br/>  "dynamodb": true,<br/>  "s3": true<br/>}</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to build endpoint service names. If null, uses the provider region. | `string` | `null` | no |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | List of route table IDs to attach the gateway endpoints to (typically private route tables). | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where gateway endpoints will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_endpoint_id"></a> [dynamodb\_endpoint\_id](#output\_dynamodb\_endpoint\_id) | VPC endpoint ID for DynamoDB gateway endpoint (null if disabled). |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | Map of gateway endpoint service => VPC endpoint ID. |
| <a name="output_s3_endpoint_id"></a> [s3\_endpoint\_id](#output\_s3\_endpoint\_id) | VPC endpoint ID for S3 gateway endpoint (null if disabled). |
<!-- END_TF_DOCS -->

````


