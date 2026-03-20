# NAT Gateway Module

Reusable Terraform module to create AWS NAT Gateway(s) and configure outbound routing for private subnets.

## Features (v1)

- Two modes:
  - **per_az** (recommended): one NAT Gateway per AZ (higher availability)
  - **single** (cheaper dev): one NAT Gateway for all private route tables
- Optional creation of private default routes (`0.0.0.0/0`) pointing to NAT
- Optional EIP reuse:
  - create EIPs automatically **or**
  - reuse existing EIP allocation IDs
- Consistent tagging:
  - `Project`, `Environment`, `ManagedBy` are enforced
  - additional `common_tags` are merged

> This module assumes networking primitives already exist (VPC, public subnets, private route tables).  
> It is intentionally kept separate from the Network module to stay modular and reusable.

---

## Usage

This module expects wiring inputs from your networking layer (typically `modules/network` outputs):

- `public_subnet_ids_by_az` — map of AZ name => public subnet ID
- `private_route_table_ids_by_az` — map of AZ name => private route table ID

### Per-AZ NAT (recommended)

```hcl
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  project_name = "my-project"
  environment  = "dev"

  public_subnet_ids_by_az = module.network.public_subnet_ids_by_az
  private_route_table_ids_by_az = module.network.private_route_table_ids_by_az

  mode          = "per_az"
  create_routes = true

  common_tags = {
    Team = "Platform"
  }
}
````

### Single NAT (cheaper dev)

```hcl
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  project_name = "my-project"
  environment  = "dev"

  public_subnet_ids_by_az = module.network.public_subnet_ids_by_az
  private_route_table_ids_by_az = module.network.private_route_table_ids_by_az

  mode          = "single"
  create_routes = true

  common_tags = {
    Team = "Platform"
  }
}
```

---

## Examples

See:

* `examples/per_az`
* `examples/single`

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
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming/tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_create_routes"></a> [create\_routes](#input\_create\_routes) | Whether to create default routes in private route tables pointing to the NAT Gateway(s). | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create NAT Gateway resources and routes. | `bool` | `true` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | NAT mode: per\_az (recommended) or single (cheaper dev). | `string` | `"per_az"` | no |
| <a name="input_private_route_table_ids_by_az"></a> [private\_route\_table\_ids\_by\_az](#input\_private\_route\_table\_ids\_by\_az) | Map of AZ name => private route table ID (from modules/network). Required when enabled=true. | `map(string)` | `{}` | no |
| <a name="input_public_subnet_ids_by_az"></a> [public\_subnet\_ids\_by\_az](#input\_public\_subnet\_ids\_by\_az) | Map of AZ name => public subnet ID (from modules/network). Required when enabled=true. | `map(string)` | `{}` | no |
| <a name="input_reuse_eip_allocation_ids"></a> [reuse\_eip\_allocation\_ids](#input\_reuse\_eip\_allocation\_ids) | Optional list of existing EIP allocation IDs to reuse. If provided, the module will not create new EIPs. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eip_allocation_ids"></a> [eip\_allocation\_ids](#output\_eip\_allocation\_ids) | Map of NAT key => EIP allocation ID used by the NAT Gateway. |
| <a name="output_mode"></a> [mode](#output\_mode) | Effective NAT mode used by the module (per\_az or single). |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | Map of NAT key => NAT Gateway ID. Keys are AZ names in per\_az mode or 'single' in single mode. |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | Map of NAT key => public IP address of the NAT Gateway. |
<!-- END_TF_DOCS -->

```

---

