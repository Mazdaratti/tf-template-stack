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
   * create the GitHub Actions deployment role and configure OIDC trust used later for deployment automation

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

New infrastructure is added by appending additional module blocks to `main.tf`.

---

## Architecture flow

This environment is built in layers so that foundational infrastructure is created first and reused by higher-level modules.

Current composition flow:

1. **Network foundation**
   - `network`
   - `nat_gateway`

2. **Private connectivity to AWS services**
   - `vpc_gateway_endpoints`
   - `vpc_interface_endpoints`

3. **Shared data protection and logging**
   - `kms_keys`
   - `s3_bucket`
   - `logging_baseline`
   - `vpc_flow_logs`

4. **Private DNS**
   - `route53_private_zones`

5. **Compute foundation**
   - `ecs_cluster`

6. **Shared ingress**
   - `alb_ingress`

7. **Workload service layer**
   - `ecs_fargate_service`

This structure keeps responsibilities separated:

* networking modules provide connectivity primitives
* logging and storage modules provide shared platform services
* DNS provides internal name resolution
* compute foundation modules provide the cluster baseline for workloads
* ingress modules provide shared load balancing
* workload modules attach application services onto the shared platform baseline

The current ECS layer is split into:

* `ecs_cluster` for the cluster foundation
* `ecs_fargate_service` for service-level resources such as:
  * task definitions
  * ECS services
  * service security groups
  * service log groups

This keeps cluster, ingress, and workload responsibilities cleanly separated.

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

## KMS Keys (encryption baseline)

Creates foundational **KMS keys** used for encryption across the platform.

Implemented via:

* `modules/kms_keys`

Current dev baseline keys:

* `logs` — intended for CloudWatch Logs / VPC Flow Logs
* `s3` — intended for S3 bucket encryption
* `secretsmanager` — for Secrets Manager
* `ssm` — for SSM Parameter Store (SecureString)

Key characteristics:

* one alias per key (auto-generated)
* safe default key policy (prevents lockout)
* optional custom key policies
* consistent tagging

This establishes a reusable encryption baseline for future modules
(e.g. logging, storage, compute).

---

## S3 Buckets (storage baseline)

Creates a secure storage baseline using reusable S3 bucket modules.

Implemented via:

* `modules/s3_bucket`

This environment deploys two buckets:

### `s3_bucket_logs`

Centralized logs bucket intended for:

* S3 Server Access Logs
* ALB access logs
* future VPC Flow Logs / CloudTrail integration

Characteristics:

* SSE-KMS encryption using the dedicated `logs` KMS key
* versioning enabled
* lifecycle rules for cost control
* restricted bucket policy allowing:
  * S3 server access log delivery from the app bucket
  * ALB access log delivery from the dev ingress layer
  * policy definitions live in `s3_bucket_policies.tf`

---

### `s3_bucket_app`

Example application storage bucket.

Characteristics:

* SSE-KMS encryption using the dedicated `s3` KMS key
* versioning enabled
* S3 Server Access Logging enabled
  * logs delivered to `s3_bucket_logs`
  * stored under prefix `app/`

---

### Why two buckets?

Separating logs and application storage:

* reduces blast radius between data domains
* enables different lifecycle strategies
* prepares the stack for future logging modules
* follows real-world platform design patterns

This establishes a durable storage baseline that can be reused by:

* application workloads
* CI/CD artifact storage
* ALB access logs
* future logging modules

---

## Logging baseline (CloudWatch Log Groups)

Creates shared CloudWatch Log Groups used as platform logging primitives.

Implemented via:

* `modules/logging_baseline`

Current dev baseline:

* `vpc_flow_logs` — shared log group intended for the upcoming `vpc_flow_logs` module

Characteristics:

* naming pattern:
```

/<project>/<environment>/vpc-flow-logs

```
* 30-day retention in dev
* production environments should typically use 90+ days
* encrypted using the dedicated `logs` KMS key created by `kms_keys`
* consistent tagging (`Project`, `Environment`, `ManagedBy`, `common_tags`)

Why this exists:

* separates log group creation from flow log configuration
* enables consistent retention and encryption standards
* keeps the environment thin
* prepares the stack for the next module: `vpc_flow_logs`

This module establishes the logging primitives that other infrastructure components will consume.

---

## VPC Flow Logs (network observability baseline)

Enables **VPC Flow Logs** for the dev VPC and publishes records to the shared CloudWatch Log Group created by the logging baseline.

Implemented via:

* `modules/vpc_flow_logs`

Current dev baseline behavior:

* source VPC: `module.network.vpc_id`
* destination log group: `module.logging_baseline.log_group_arns["vpc_flow_logs"]`
* traffic type: `ALL` (module default)
* max aggregation interval: `600` seconds (module default)

Key characteristics:

* uses CloudWatch Logs destination
* creates a dedicated IAM role for Flow Logs delivery
* keeps destination Log Group ownership in `logging_baseline`
* applies consistent repository tagging

Why this module is separate:

* keeps environment composition thin
* preserves clear module boundaries:
  * `logging_baseline` manages log groups
  * `vpc_flow_logs` manages VPC Flow Log delivery
* makes future extension straightforward (additional VPCs, stricter settings per environment)

Validation / Testing:

After `terraform apply`, you can validate the setup:

1) Confirm Flow Logs is enabled for the VPC:

- AWS Console:
  - VPC → Your VPC → **Flow logs**
  - Verify status is **ACTIVE**
  - Verify destination is **CloudWatch Logs**

2) Confirm logs arrive in CloudWatch:

- CloudWatch → Log groups
- Open the log group created by `logging_baseline` for:
  - `vpc_flow_logs`
- Wait for the first log streams/records (traffic must exist)

---

## Route53 Private Zones (private DNS baseline)

Creates a baseline **private DNS namespace** for the dev environment using Route53 private hosted zones.

Implemented via:

* `modules/route53_private_zones`

Current dev baseline behavior:

* private hosted zone logical key: `internal`
* zone name pattern: `${environment}.internal` (dev resolves to `dev.internal`)
* associated VPC: `module.network.vpc_id`
* records: none by default (kept optional/commented in `main.tf`)

Key characteristics:

* private hosted zone only (no public hosted zones in this baseline)
* supports one-or-more VPC associations per zone
* supports optional baseline records (`A`, `AAAA`, `CNAME`, `TXT`)
* applies consistent repository tagging

Why this module is separate:

* keeps DNS concerns isolated from network and endpoint modules
* keeps env composition thin while preserving reusable module logic
* provides a clean extension path for future internal service discovery needs

---

## ECS Cluster (compute baseline)

Creates the ECS cluster used as the compute foundation for the dev environment.

Implemented via:

* `modules/ecs_cluster`

Current dev configuration:

* creates one ECS cluster (cluster-level primitive only)
* optional cluster name override via `ecs_cluster_name`
* Container Insights controlled by `ecs_enable_container_insights` (enabled by default)
* ECS Exec is disabled in the dev baseline (`exec_enabled = false`)
* capacity providers use the module defaults (`FARGATE`, `FARGATE_SPOT`)

Key characteristics:

* cluster foundation only (no services or task definitions in this layer)
* consistent repository tagging
* environment remains composition-focused with reusable module boundaries

Future extension path:

* the baseline continues using module defaults for capacity providers
* ECS Exec can later be enabled with `exec_logging = "OVERRIDE"`
* when enabling ECS Exec with override logging, a CloudWatch log group must be provided

Why this module is separate:

* keeps compute control-plane concerns isolated from network/storage/logging modules
* provides a reusable ECS cluster that future ECS service modules can consume
* preserves thin environment composition

---

## ALB Ingress (shared ingress baseline)

Creates the shared Application Load Balancer layer for future ECS service modules.

Implemented via:

* `modules/alb_ingress`

Current dev configuration:

* creates one **internal** ALB
* places the ALB into `module.network.private_subnet_ids`
* allows ingress from within the VPC CIDR (`var.vpc_cidr`)
* creates one HTTP listener on port `80`
* creates one IP target group for future ECS/Fargate service attachment
* enables ALB access logs to the shared logs bucket under the `alb/` prefix

Key characteristics:

* ALB security group is managed inside the module
* security group rules use standalone rule resources (no inline rules)
* listener and target group wiring remain simple and baseline-focused
* outputs are exposed for future ECS service and Route53 integration

Why this module is separate:

* keeps ECS cluster scope limited to cluster-level concerns
* keeps DNS concerns outside the ingress layer
* provides a reusable ingress primitive for future service modules
* preserves thin environment composition

Workload services attach to shared target groups without re-owning ingress infrastructure.

---

## ECS Fargate Service (workload baseline)

Creates the first real ECS workload service layer for the dev environment.

Implemented via:

* `modules/ecs_fargate_service`

Current dev baseline characteristics:

* runs in private subnets
* does not assign public IPs
* attaches to the shared ALB ingress target group created by `alb_ingress`
* allows ingress only from the ALB security group
* creates a dedicated service security group
* creates a dedicated CloudWatch Log Group encrypted with the shared logs KMS key

Why this module exists:

* keeps `ecs_cluster` focused on cluster-level concerns only
* keeps shared ALB ownership in `alb_ingress`
* moves workload-specific service resources into a reusable service module
* demonstrates the intended platform -> ingress -> service composition in `envs/dev`

---

## Optional endpoint policies

This environment includes a **commented policy template**:

* `endpoint_policies.tf.example`

It demonstrates:

* broad (default-like) policies
* restricted policies (recommended)
* how to inject ARNs from other modules (e.g. storage, database)

Active endpoint policies must be defined in `endpoint_policies.tf`.

Policies are **disabled by default** and only applied if explicitly enabled.

---

## Optional KMS key policies

This environment includes a **commented policy template**:

* `kms_key_policies.tf.example`

It demonstrates:

* safe admin baseline policy (recommended)
* delegated usage to IAM roles (template pattern)
* how to pass custom policy JSON into the `kms_keys` module

Active key policies must be defined in `kms_key_policies.tf`.

Policies are **disabled by default** and only applied if explicitly enabled.

---

## Files in this folder

* `main.tf` — wires infrastructure modules together
* `providers.tf` — AWS provider configuration
* `versions.tf` — Terraform and provider constraints
* `variables.tf` — environment-level inputs
* `outputs.tf` — environment outputs
* `data.tf` — shared AWS data sources (account identity, future region/partition)
* `dev.tfvars.example` — documented variable examples
* `backend.tf.example` — backend configuration example
* `endpoint_policies.tf` — active VPC endpoint policy definitions (if used)
* `endpoint_policies.tf.example` — endpoint policy templates (gateway + interface)
* `kms_key_policies.tf` — active KMS key policy definitions (if used)
* `kms_key_policies.tf.example` — KMS key policy templates
* `security_groups.tf` — active security group definitions (if used)
* `security_groups.tf.example` — security group templates (external/shared SG pattern)
* `s3_bucket_policies.tf` — active S3 bucket policy definitions (S3 and ALB log delivery restrictions)


---

## Design principles

* Keep this environment **thin**
* Prefer reusable logic inside modules
* Treat this folder as a **composition layer**
* Add new infrastructure by appending new module sections

---

## Usage

If not already done:
> Run `bootstrap/dev` first to generate `backend.tf` and provision the GitHub Actions deployment role. This step must be executed once per AWS account. The CI validation workflow does not use that role.

Run the following commands from inside `envs/dev/`.

```shell
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

---

## GitHub Actions deployment prerequisites

The repository includes a manual GitHub Actions deployment workflow for `envs/dev`.

Before using that workflow:

1. run `bootstrap/dev` manually
2. collect the required backend and deploy-role values from bootstrap outputs
3. store them in the GitHub Environment named `dev`

Recommended GitHub Environment `dev` variables:

- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`
- `TF_BACKEND_DYNAMODB_TABLE`
- `TF_BACKEND_KEY`
- `TF_VAR_project_name`
- `TF_VAR_vpc_cidr`
- `TF_VAR_ecs_service_image_uri`

Recommended values:

- `TF_BACKEND_KEY = envs/dev/terraform.tfstate`
- `TF_VAR_ecs_service_image_uri = nginx:stable-alpine`

The GitHub Actions deployment workflow does not use the local `dev.tfvars` file.
It generates a temporary configuration during execution based on GitHub Environment variables.

The deployment workflow then:

- regenerates `backend.tf`
- regenerates `dev.tfvars`
- runs Terraform `init`, `validate`, `plan`, and `apply`
- waits for ECS service stability
- verifies ALB target group health through AWS APIs

Why no HTTP smoke test from GitHub Actions?

- the ALB in `envs/dev` is internal/private
- GitHub-hosted runners are outside the VPC
- the workflow therefore uses ECS service state and target group health as the v1 smoke-test baseline

---

## Cost considerations (important)

This dev environment creates resources that incur hourly charges:

- NAT Gateway
- Application Load Balancer
- ECS Fargate tasks

Even when traffic is low, these resources may generate costs.

To avoid unexpected charges:

- destroy the environment when not actively testing
- configure AWS Budgets alerts
- prefer `single` NAT mode in dev
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

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.35.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_ingress"></a> [alb\_ingress](#module\_alb\_ingress) | ../../modules/alb_ingress | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../../modules/ecs_cluster | n/a |
| <a name="module_ecs_fargate_service"></a> [ecs\_fargate\_service](#module\_ecs\_fargate\_service) | ../../modules/ecs_fargate_service | n/a |
| <a name="module_kms_keys"></a> [kms\_keys](#module\_kms\_keys) | ../../modules/kms_keys | n/a |
| <a name="module_logging_baseline"></a> [logging\_baseline](#module\_logging\_baseline) | ../../modules/logging_baseline | n/a |
| <a name="module_nat_gateway"></a> [nat\_gateway](#module\_nat\_gateway) | ../../modules/nat_gateway | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/network | n/a |
| <a name="module_route53_private_zones"></a> [route53\_private\_zones](#module\_route53\_private\_zones) | ../../modules/route53_private_zones | n/a |
| <a name="module_s3_bucket_app"></a> [s3\_bucket\_app](#module\_s3\_bucket\_app) | ../../modules/s3_bucket | n/a |
| <a name="module_s3_bucket_logs"></a> [s3\_bucket\_logs](#module\_s3\_bucket\_logs) | ../../modules/s3_bucket | n/a |
| <a name="module_vpc_flow_logs"></a> [vpc\_flow\_logs](#module\_vpc\_flow\_logs) | ../../modules/vpc_flow_logs | n/a |
| <a name="module_vpc_gateway_endpoints"></a> [vpc\_gateway\_endpoints](#module\_vpc\_gateway\_endpoints) | ../../modules/vpc_gateway_endpoints | n/a |
| <a name="module_vpc_interface_endpoints"></a> [vpc\_interface\_endpoints](#module\_vpc\_interface\_endpoints) | ../../modules/vpc_interface_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.alb_access_logs_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs_bucket_combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access_logs_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpce_s3_restricted_to_env_buckets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"eu-central-1"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | The number of availability zones to use if explicit AZ list is not provided (module will pick the first N AZs in region). | `number` | `2` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Optional explicit list of availability zones to use. If set, az\_count is ignored. | `list(string)` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags passed into modules (merged with enforced tags inside each module). | `map(string)` | `{}` | no |
| <a name="input_create_private_subnets"></a> [create\_private\_subnets](#input\_create\_private\_subnets) | Whether to create private subnets and private routing (NAT + private route table). | `bool` | `true` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | Whether to create public subnets and public routing (IGW + public route table). | `bool` | `true` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Optional ECS cluster name override. If null, module default naming is used. | `string` | `null` | no |
| <a name="input_ecs_enable_container_insights"></a> [ecs\_enable\_container\_insights](#input\_ecs\_enable\_container\_insights) | Whether to enable ECS Container Insights for the dev cluster baseline. | `bool` | `true` | no |
| <a name="input_ecs_service_image_uri"></a> [ecs\_service\_image\_uri](#input\_ecs\_service\_image\_uri) | Container image URI for the dev ECS Fargate service.<br/><br/>This is the only workload-specific input exposed at the env layer in v1.<br/>Service sizing, port, subnet placement, logging, and ALB integration stay<br/>opinionated in envs/dev to keep the baseline small and predictable. | `string` | n/a | yes |
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
| <a name="output_alb_ingress_arn"></a> [alb\_ingress\_arn](#output\_alb\_ingress\_arn) | ARN of the internal ALB created for the dev ingress baseline. |
| <a name="output_alb_ingress_dns_name"></a> [alb\_ingress\_dns\_name](#output\_alb\_ingress\_dns\_name) | DNS name of the internal ALB created for the dev ingress baseline. |
| <a name="output_alb_ingress_listener_arns"></a> [alb\_ingress\_listener\_arns](#output\_alb\_ingress\_listener\_arns) | Map of listener key => listener ARN for the dev ALB ingress baseline. |
| <a name="output_alb_ingress_security_group_id"></a> [alb\_ingress\_security\_group\_id](#output\_alb\_ingress\_security\_group\_id) | Security group ID created for the dev ALB ingress baseline. |
| <a name="output_alb_ingress_target_group_arns"></a> [alb\_ingress\_target\_group\_arns](#output\_alb\_ingress\_target\_group\_arns) | Map of target group key => target group ARN for the dev ALB ingress baseline. |
| <a name="output_alb_ingress_target_group_names"></a> [alb\_ingress\_target\_group\_names](#output\_alb\_ingress\_target\_group\_names) | Map of target group key => target group name for the dev ALB ingress baseline. |
| <a name="output_alb_ingress_zone_id"></a> [alb\_ingress\_zone\_id](#output\_alb\_ingress\_zone\_id) | Canonical hosted zone ID of the internal ALB created for the dev ingress baseline. |
| <a name="output_azs"></a> [azs](#output\_azs) | Availability zones used by the network module. |
| <a name="output_dynamodb_gateway_endpoint_id"></a> [dynamodb\_gateway\_endpoint\_id](#output\_dynamodb\_gateway\_endpoint\_id) | VPC Endpoint ID for DynamoDB gateway endpoint (null if disabled). |
| <a name="output_ecs_capacity_providers"></a> [ecs\_capacity\_providers](#output\_ecs\_capacity\_providers) | Set of capacity providers associated with the dev ECS cluster. |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS cluster created for the dev environment. |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ID of the ECS cluster created for the dev environment. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster created for the dev environment. |
| <a name="output_ecs_default_capacity_provider_strategy"></a> [ecs\_default\_capacity\_provider\_strategy](#output\_ecs\_default\_capacity\_provider\_strategy) | Default capacity provider strategy configured on the dev ECS cluster (null if not configured). |
| <a name="output_ecs_service_arn"></a> [ecs\_service\_arn](#output\_ecs\_service\_arn) | ARN of the ECS Fargate service created for the dev workload baseline. |
| <a name="output_ecs_service_id"></a> [ecs\_service\_id](#output\_ecs\_service\_id) | ID of the ECS Fargate service created for the dev workload baseline. |
| <a name="output_ecs_service_log_group_name"></a> [ecs\_service\_log\_group\_name](#output\_ecs\_service\_log\_group\_name) | CloudWatch Log Group name created for the dev ECS Fargate service. |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the ECS Fargate service created for the dev workload baseline. |
| <a name="output_ecs_service_security_group_id"></a> [ecs\_service\_security\_group\_id](#output\_ecs\_service\_security\_group\_id) | Security group ID created for the dev ECS Fargate service. |
| <a name="output_ecs_service_task_definition_arn"></a> [ecs\_service\_task\_definition\_arn](#output\_ecs\_service\_task\_definition\_arn) | ARN of the ECS task definition used by the dev workload baseline. |
| <a name="output_enabled_interface_endpoint_services"></a> [enabled\_interface\_endpoint\_services](#output\_enabled\_interface\_endpoint\_services) | Set of enabled interface endpoint service keys. |
| <a name="output_gateway_endpoints_ids"></a> [gateway\_endpoints\_ids](#output\_gateway\_endpoints\_ids) | Map of service name => VPC Endpoint ID for gateway endpoints (S3, DynamoDB). |
| <a name="output_interface_endpoint_arns"></a> [interface\_endpoint\_arns](#output\_interface\_endpoint\_arns) | Map of service name => VPC Endpoint ARN for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_dns_entries"></a> [interface\_endpoint\_dns\_entries](#output\_interface\_endpoint\_dns\_entries) | Map of service name => list of DNS entries for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_ids"></a> [interface\_endpoint\_ids](#output\_interface\_endpoint\_ids) | Map of service name => VPC Endpoint ID for interface endpoints (PrivateLink). |
| <a name="output_interface_endpoint_security_group_id"></a> [interface\_endpoint\_security\_group\_id](#output\_interface\_endpoint\_security\_group\_id) | Security group ID created by the module (null here because SG is managed externally). |
| <a name="output_kms_alias_names"></a> [kms\_alias\_names](#output\_kms\_alias\_names) | Map of KMS key name => alias name. |
| <a name="output_kms_key_arns"></a> [kms\_key\_arns](#output\_kms\_key\_arns) | Map of KMS key name => key ARN. |
| <a name="output_kms_key_ids"></a> [kms\_key\_ids](#output\_kms\_key\_ids) | Map of KMS key name => key ID. |
| <a name="output_kms_keys"></a> [kms\_keys](#output\_kms\_keys) | Map of KMS key name => object with key\_arn, key\_id, and alias\_name. |
| <a name="output_logging_baseline_log_group_arns"></a> [logging\_baseline\_log\_group\_arns](#output\_logging\_baseline\_log\_group\_arns) | Map of log group key => CloudWatch Log Group ARN created by logging\_baseline. |
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
| <a name="output_route53_private_record_fqdns"></a> [route53\_private\_record\_fqdns](#output\_route53\_private\_record\_fqdns) | Map of '<zone\_key>::<record\_key>' => computed Route53 private record FQDN. |
| <a name="output_route53_private_zone_ids"></a> [route53\_private\_zone\_ids](#output\_route53\_private\_zone\_ids) | Map of logical zone key => Route53 private hosted zone ID. |
| <a name="output_route53_private_zone_names"></a> [route53\_private\_zone\_names](#output\_route53\_private\_zone\_names) | Map of logical zone key => Route53 private hosted zone DNS name. |
| <a name="output_s3_app_bucket_arn"></a> [s3\_app\_bucket\_arn](#output\_s3\_app\_bucket\_arn) | S3 bucket ARN for application data. |
| <a name="output_s3_app_bucket_name"></a> [s3\_app\_bucket\_name](#output\_s3\_app\_bucket\_name) | S3 bucket name for application data (source bucket). |
| <a name="output_s3_gateway_endpoint_id"></a> [s3\_gateway\_endpoint\_id](#output\_s3\_gateway\_endpoint\_id) | VPC Endpoint ID for S3 gateway endpoint (null if disabled). |
| <a name="output_s3_logs_bucket_arn"></a> [s3\_logs\_bucket\_arn](#output\_s3\_logs\_bucket\_arn) | S3 bucket ARN for centralized logs. |
| <a name="output_s3_logs_bucket_name"></a> [s3\_logs\_bucket\_name](#output\_s3\_logs\_bucket\_name) | S3 bucket name for centralized logs (destination for access logging). |
| <a name="output_vpc_flow_log_id"></a> [vpc\_flow\_log\_id](#output\_vpc\_flow\_log\_id) | ID of the VPC Flow Log created for the dev VPC. |
| <a name="output_vpc_flow_logs_iam_role_arn"></a> [vpc\_flow\_logs\_iam\_role\_arn](#output\_vpc\_flow\_logs\_iam\_role\_arn) | ARN of the IAM role used by VPC Flow Logs. |
| <a name="output_vpc_flow_logs_log_group_arn"></a> [vpc\_flow\_logs\_log\_group\_arn](#output\_vpc\_flow\_logs\_log\_group\_arn) | CloudWatch Log Group ARN for VPC Flow Logs (shared log group created by logging\_baseline). |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
