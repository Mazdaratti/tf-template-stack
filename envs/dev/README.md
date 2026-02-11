# Development Environment (dev)

This folder contains the Terraform **root module** for the **dev** environment.

It is part of the **tf-template-stack** and is designed to be:

* reusable across real-world projects
* easy to extend by adding new modules
* thin (composition only, no complex logic)

---

## Remote backend model used in this template

This template uses a **remote Terraform backend** (S3 + DynamoDB) for:

* state storage
* state locking

⚠️ **You do NOT create `backend.tf` manually.**

Instead:

1. Run the bootstrap stack:

   * `bootstrap/dev`
2. The bootstrap stack will:

   * create the S3 state bucket
   * create the DynamoDB lock table
   * generate `envs/dev/backend.tf` automatically

`backend.tf` is treated as a **generated artifact**.

> `backend.tf.example` exists only to document the expected backend configuration shape.
> ⚠️ Never commit `backend.tf` — it is environment- and account-specific.

---

## How to use this environment

### Step 1 — Configure variables

Copy the example file and adjust values:

```
dev.tfvars.example → dev.tfvars
```

This environment supports two configuration styles:

#### A) Hybrid defaults (recommended)

You define:

* VPC CIDR
* number of AZs
* number of public/private subnets

Subnet CIDRs are derived automatically.

#### B) Explicit values (full control)

You define:

* explicit AZ list
* explicit public subnet CIDRs
* explicit private subnet CIDRs

---

# What this environment deploys

The dev environment is composed of reusable modules.

Each section below corresponds to **one module block in `main.tf`**.

New infrastructure is added by appending additional module blocks.

---

## Network baseline

Creates the foundational VPC layer:

* VPC
* public & private subnets
* route tables
* internet gateway

Implemented via:

* `modules/network`

---

## NAT Gateway (private outbound internet access)

Provides outbound internet access for private subnets.

Implemented via:

* `modules/nat_gateway`

Supported modes:

* `single` — cheaper, suitable for dev
* `per_az` — recommended for production-like setups

---

## Gateway VPC Endpoints (S3, DynamoDB)

Provides **private connectivity** from private subnets to:

* Amazon S3
* Amazon DynamoDB

Implemented via:

* `modules/vpc_gateway_endpoints`

Key characteristics:

* attached to **private route tables**
* removes the need for NAT access to S3/DynamoDB
* supports optional endpoint policies

---

## Interface VPC Endpoints (PrivateLink)

Provides **private connectivity** from private subnets to AWS services using Interface Endpoints (ENIs in subnets).

Implemented via:

* `modules/vpc_interface_endpoints`

Typical baseline for private compute environments:

* `ssm`
* `ec2messages`
* `ssmmessages`
* `logs`
* `secretsmanager`

Key characteristics:

* placed into **private subnets**
* controlled via **security groups**
* supports optional endpoint policies
* enables fully private SSM-based access (no bastion required)

---

## Optional endpoint policies

This environment includes a **commented policy template**:

* `endpoint_policies.tf`

It demonstrates:

* broad (default-like) policies
* restricted policies (recommended)
* how to inject ARNs from other modules (e.g. storage, database)

Policies are **disabled by default** and only applied if explicitly enabled.

---

## Files in this folder

* `main.tf` — wires infrastructure modules together
* `providers.tf` — AWS provider configuration
* `versions.tf` — Terraform and provider constraints
* `variables.tf` — environment-level inputs
* `outputs.tf` — environment outputs
* `dev.tfvars.example` — documented variable examples
* `backend.tf.example` — backend configuration example
* `endpoint_policies.tf` — commented endpoint policy templates (gateways + interface)
* `security_groups.tf` — commented security group templates (external/shared SG pattern)
---

## Design principles

* Keep this environment **thin**
* Prefer reusable logic inside modules
* Treat this folder as a **composition layer**
* Add new infrastructure by appending new module sections

---

## Usage

Run the following commands from inside `envs/dev/`.

> If using the remote backend, run `bootstrap/dev` first to generate `backend.tf`.

```shell
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```
---

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
| <a name="module_vpc_gateway_endpoints"></a> [vpc\_gateway\_endpoints](#module\_vpc\_gateway\_endpoints) | ../../modules/vpc_gateway_endpoints | n/a |
| <a name="module_vpc_interface_endpoints"></a> [vpc\_interface\_endpoints](#module\_vpc\_interface\_endpoints) | ../../modules/vpc_interface_endpoints | n/a |

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
| <a name="output_dynamodb_gateway_endpoint_id"></a> [dynamodb\_gateway\_endpoint\_id](#output\_dynamodb\_gateway\_endpoint\_id) | VPC Endpoint ID for DynamoDB gateway endpoint (null if disabled). |
| <a name="output_enabled_interface_endpoint_services"></a> [enabled\_interface\_endpoint\_services](#output\_enabled\_interface\_endpoint\_services) | Set of enabled interface endpoint service keys. |
| <a name="output_gateway_endpoints_ids"></a> [gateway\_endpoints\_ids](#output\_gateway\_endpoints\_ids) | Map of service name => VPC Endpoint ID for gateway endpoints (S3, DynamoDB). |
| <a name="output_interface_endpoint_arns"></a> [interface\_endpoint\_arns](#output\_interface\_endpoint\_arns) | Map of service name => VPC Endpoint ARN for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_dns_entries"></a> [interface\_endpoint\_dns\_entries](#output\_interface\_endpoint\_dns\_entries) | Map of service name => list of DNS entries for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_ids"></a> [interface\_endpoint\_ids](#output\_interface\_endpoint\_ids) | Map of service name => VPC Endpoint ID for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_security_group_id"></a> [interface\_endpoint\_security\_group\_id](#output\_interface\_endpoint\_security\_group\_id) | Security group ID created by the module (null here because SG is managed externally). |
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
| <a name="output_s3_gateway_endpoint_id"></a> [s3\_gateway\_endpoint\_id](#output\_s3\_gateway\_endpoint\_id) | VPC Endpoint ID for S3 gateway endpoint (null if disabled). |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
