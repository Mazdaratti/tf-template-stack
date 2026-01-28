# Network Module (VPC)

Reusable Terraform module to create an AWS VPC with configurable public and private subnets.

## Features (v1)

- VPC with DNS support/hostnames
- Automatic AZ selection by region (or explicit AZ list)
- Hybrid subnet configuration:
  - provide explicit CIDRs **or**
  - derive them automatically from the VPC CIDR
- Optional public subnets + Internet Gateway + public route table
- Optional private subnets + private route tables (per AZ)
- Consistent tagging:
  - `Project`, `Environment`, `ManagedBy` are enforced
  - additional `common_tags` are merged

> NAT Gateways and private outbound routing are intentionally not included in v1.  
> They will be added in a later version in a backward-compatible way.

---

## Usage

### Basic (hybrid defaults)

```hcl
module "network" {
  source = "../../modules/network"

  project_name = "my-project"
  environment  = "dev"

  vpc_cidr = "10.10.0.0/16"
  az_count = 2

  public_subnet_count  = 2
  private_subnet_count = 2

  common_tags = {
    Team = "Platform"
  }
}
````

### Explicit subnets (full control)

```hcl
module "network" {
  source = "../../modules/network"

  project_name = "my-project"
  environment  = "dev"

  vpc_cidr = "10.20.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"]

  public_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
  private_subnet_cidrs = ["10.20.110.0/24", "10.20.111.0/24"]

  common_tags = {
    Team = "Platform"
  }
}
```

---

## Examples

See:

* `examples/basic_usage`
* `examples/explicit_values`

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
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.public_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | The number of availability zones to use if 'azs' is not provided. | `number` | `2` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones to use for the VPC subnets. | `list(string)` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | A map of common tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_create_private_subnets"></a> [create\_private\_subnets](#input\_create\_private\_subnets) | A boolean flag to enable/disable creation of private subnets. | `bool` | `true` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | A boolean flag to enable/disable creation of public subnets. | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | A boolean flag to enable/disable DNS hostnames in the VPC. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | A boolean flag to enable/disable DNS support in the VPC. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for naming/tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | A boolean flag to enable/disable mapping public IPs on launch for public subnets. | `bool` | `true` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | Optional explicit list of CIDR blocks for private subnets. If set, private\_subnet\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_private_subnet_count"></a> [private\_subnet\_count](#input\_private\_subnet\_count) | The number of private subnets to create if 'create\_private\_subnets' is true. | `number` | `2` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging. | `string` | n/a | yes |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | Optional explicit list of CIDR blocks for public subnets.If set, public\_subnet\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_public_subnet_count"></a> [public\_subnet\_count](#input\_public\_subnet\_count) | The number of public subnets to create if 'create\_public\_subnets' is true. | `number` | `2` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azs"></a> [azs](#output\_azs) | A list of availability zones specified as argument to this module |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | The ID of the internet gateway if created, otherwise null |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | A map of AZ name =>private route table ID (empty if none) |
| <a name="output_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#output\_private\_subnet\_cidrs) | A list of CIDRs of private subnets (empty if none) |
| <a name="output_private_subnets_ids"></a> [private\_subnets\_ids](#output\_private\_subnets\_ids) | A list of IDs of private subnets (empty if none) |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | The ID of the public route table if created, otherwise null |
| <a name="output_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#output\_public\_subnet\_cidrs) | A list of CIDRs of public subnets (empty if none) |
| <a name="output_public_subnets_ids"></a> [public\_subnets\_ids](#output\_public\_subnets\_ids) | A list of IDs of public subnets (empty if none) |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->

```
