# Development Environment (dev)

This folder contains the Terraform root configuration for the **dev** environment.

It is part of the **tf-template-stack** template and is meant to be reusable in real-world projects.

---

## How remote backend works in this template

This template uses a remote Terraform backend (S3 + DynamoDB) for state storage and state locking.

✅ You do NOT create `backend.tf` manually in this template.

Instead:

1. Run the bootstrap stack:
   - `bootstrap/dev`
2. Bootstrap will:
   - create the S3 state bucket + DynamoDB lock table
   - generate `envs/dev/backend.tf` automatically

`backend.tf` is treated as a generated artifact.

> `backend.tf.example` exists only to document what the generated backend configuration looks like.  
> ⚠️ Do not commit `backend.tf` — it is generated per environment and may differ between accounts/projects.

---

## How to use this environment

### Step 1 — Configure variables
Copy the example file and adjust values:

- `dev.tfvars.example` → `dev.tfvars`

This template supports two styles:

#### A) Hybrid defaults (recommended)
You set:
- VPC CIDR
- number of AZs
- number of public/private subnets

Subnet CIDRs are derived automatically.

#### B) Explicit values (full control)
You set:
- explicit AZ list
- explicit public/private subnet CIDRs

---

## What this environment deploys (current state)

✅ Network baseline (VPC + subnets + routing)
- Implemented via `modules/network`

✅ NAT Gateway (private outbound internet)
- Implemented via `modules/nat_gateway`
- Supports:
  - `single` (cheaper dev)
  - `per_az` (recommended)


More modules will be added over time (compute, load balancer, storage, etc.).

---

## Files in this folder

- `main.tf` — calls infrastructure modules (starting with `network`)
- `providers.tf` — AWS provider configuration
- `versions.tf` — Terraform/provider version constraints
- `variables.tf` — environment inputs
- `outputs.tf` — environment outputs
- `dev.tfvars.example` — documented configuration example
- `backend.tf.example` — documentation of backend config format

---

## Notes

- Keep this environment **thin**: it should mostly call modules and pass variables.
- Prefer making changes inside modules to keep code reusable across environments.

---

## Usage

Run the following commands from inside `envs/dev/`.

> If you are using the remote backend, run `bootstrap/dev` first to generate `backend.tf`.

```shell
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nat_gateway"></a> [nat\_gateway](#module\_nat\_gateway) | ../../modules/nat_gateway | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/network | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"eu-central-1"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | The number of availability zones to use if explicit AZ list is not provided (module will pick the first N AZs in region). | `number` | `2` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Optional explicit list of availability zones to use. If set, az\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags passed into modules (merged with enforced tags inside each module). | `map(string)` | `{}` | no |
| <a name="input_create_private_subnets"></a> [create\_private\_subnets](#input\_create\_private\_subnets) | Whether to create private subnets and private routing (NAT + private route table). | `bool` | `true` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | Whether to create public subnets and public routing (IGW + public route table). | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Whether instances in the VPC get DNS hostnames. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Whether DNS resolution is supported for the VPC. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Whether to create NAT Gateway resources for private outbound internet access. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Whether public subnets should map public IPs on launch. | `bool` | `true` | no |
| <a name="input_nat_create_routes"></a> [nat\_create\_routes](#input\_nat\_create\_routes) | Whether to create default routes in private route tables pointing to NAT. | `bool` | `true` | no |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | NAT mode: per\_az (recommended) or single (cheaper dev). | `string` | `"single"` | no |
| <a name="input_nat_reuse_eip_allocation_ids"></a> [nat\_reuse\_eip\_allocation\_ids](#input\_nat\_reuse\_eip\_allocation\_ids) | Optional list of existing EIP allocation IDs to reuse. If null, the module creates new EIPs. | `list(string)` | `null` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | Optional explicit list of CIDR blocks for private subnets. If set, private\_subnet\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_private_subnet_count"></a> [private\_subnet\_count](#input\_private\_subnet\_count) | Number of private subnets to create if explicit private CIDRs are not provided. | `number` | `2` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming/tagging across all modules. Must be unique across all projects in the account. | `string` | n/a | yes |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | Optional explicit list of CIDR blocks for public subnets. If set, public\_subnet\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_public_subnet_count"></a> [public\_subnet\_count](#input\_public\_subnet\_count) | Number of public subnets to create if explicit public CIDRs are not provided. | `number` | `2` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azs"></a> [azs](#output\_azs) | Availability zones used by the network module. |
| <a name="output_nat_eip_allocation_ids"></a> [nat\_eip\_allocation\_ids](#output\_nat\_eip\_allocation\_ids) | Map of NAT key => EIP allocation ID used by the NAT Gateway. |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | Map of NAT key => NAT Gateway ID. Keys are AZ names in per\_az mode or 'single' in single mode. |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | Map of NAT key => public IP address of the NAT Gateway. |
| <a name="output_private_route_table_ids_by_az"></a> [private\_route\_table\_ids\_by\_az](#output\_private\_route\_table\_ids\_by\_az) | A map of AZ name =>private route table ID (empty if none) |
| <a name="output_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#output\_private\_subnet\_cidrs) | A list of CIDRs of private subnets (empty if none) |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | A list of IDs of private subnets (empty if none) |
| <a name="output_private_subnet_ids_by_az"></a> [private\_subnet\_ids\_by\_az](#output\_private\_subnet\_ids\_by\_az) | A map of AZ name =>private subnet ID (empty if none) |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | The ID of the public route table if created, otherwise null |
| <a name="output_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#output\_public\_subnet\_cidrs) | A list of CIDRs of public subnets (empty if none) |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | A list of IDs of public subnets (empty if none) |
| <a name="output_public_subnet_ids_by_az"></a> [public\_subnet\_ids\_by\_az](#output\_public\_subnet\_ids\_by\_az) | A map of AZ name =>public subnet ID (empty if none) |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
