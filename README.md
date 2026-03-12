# TF-Template-Stack

A production-shaped Terraform template for building private AWS application platforms using reusable modules, thin environment composition, shared platform services, and ECS-based workload deployment.

This repository demonstrates a module-first Terraform architecture where networking, private connectivity, encryption, storage, logging, DNS, ingress, and ECS workloads are separated into reusable building blocks and composed through lightweight environment root modules.

---

## What this project demonstrates

- modular Terraform architecture with reusable `modules/`
- thin environment composition through `envs/*`
- private-by-default AWS networking patterns
- shared encryption, storage, and logging baselines
- private DNS and shared ALB ingress
- ECS cluster plus Fargate workload deployment
- clear separation between platform, ingress, and workload concerns

---

## Current implementation status

The repository structure supports multiple environments:

- `dev`
- `stage`
- `prod`

At the moment, the full demonstrated implementation is `envs/dev`, covering the platform baseline from network foundation through a private ECS Fargate workload behind a shared internal ALB.

The `stage` and `prod` folders currently remain extension paths for applying the same module pattern to additional environments.

---

## Architecture overview

The current `dev` environment is built in layers so lower-level infrastructure is created first and reused by higher-level modules.

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

This layered composition keeps responsibilities separated:

- networking modules provide connectivity primitives
- logging and storage modules provide shared platform services
- DNS provides internal name resolution
- compute foundation modules provide the ECS cluster baseline
- ingress modules provide shared load balancing
- workload modules attach services onto the shared platform baseline

---

## Repository structure

- **envs/**: Environment root modules (`dev`, `stage`, `prod`). Each environment composes reusable modules.
- **modules/**: Reusable Terraform modules shared across environments.
- **bootstrap/**: One-time prerequisites such as remote state backend creation, generated backend configuration, and hardened GitHub Actions deploy-role setup via OIDC.

---

## Implemented modules

- **network** — VPC + subnets + route tables (no NAT)
- **nat_gateway** — NAT Gateway(s) + private outbound routes
- **vpc_gateway_endpoints** — Gateway endpoints (S3, DynamoDB)
- **vpc_interface_endpoints** — Interface endpoints (PrivateLink services)
- **kms_keys** — Reusable KMS key creation with safe default policy
- **s3_bucket** — Secure-by-default S3 bucket with encryption, lifecycle, and access logging support
- **logging_baseline** — Shared CloudWatch Log Groups with standardized naming, retention, and optional KMS encryption
- **vpc_flow_logs** — VPC Flow Logs delivery to a shared CloudWatch Log Group
- **route53_private_zones** — Private Route53 hosted zones with multi-VPC associations and optional baseline records
- **ecs_cluster** — ECS cluster baseline with Container Insights and capacity provider controls
- **alb_ingress** — Shared internal/public ALB ingress baseline with security groups, listeners, target groups, and optional access logs
- **ecs_fargate_service** — Reusable ECS Fargate service baseline with task definition, service, IAM roles, service security group, CloudWatch logging, and optional target group attachment
- **remote_backend** — S3 + DynamoDB remote state backend for bootstrap usage

---

## Recommended implementation order

1. `bootstrap/dev`
   - create remote backend (S3 + DynamoDB)
   - set up the GitHub Actions deployment role via OIDC

2. `envs/dev`
   - network baseline
   - NAT Gateway
   - VPC endpoints
   - KMS keys
   - storage baseline
   - logging baseline
   - VPC Flow Logs
   - Route53 private zones
   - ECS cluster baseline
   - ALB ingress baseline
   - ECS Fargate service baseline

This ordering reflects the current implementation path and keeps foundational infrastructure in place before compute and workload layers.

---

## How to run

Start with the `dev` environment.

1. Run `bootstrap/dev` using `bootstrap/dev/readme.md` first to:
   - create the remote backend
   - generate `envs/dev/backend.tf`
   - create the GitHub Actions deployment role used for later deployment automation
2. Copy `envs/dev/dev.tfvars.example` to `dev.tfvars`
3. Set the required values, including the ECS workload image URI
4. Deploy from inside `envs/dev/`:

```shell
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

For the detailed environment walkthrough, see `envs/dev/README.md`.

---

## Validation and quality workflow

Recommended checks before merge:

```shell
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint
terraform-docs
```

GitHub Actions now runs the Terraform validation workflow for pull requests and for pushes to `main`.

The first CI workflow is intentionally focused on safe validation only:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- `tflint`

It validates:

- `bootstrap/dev`
- `envs/dev`
- all implemented reusable modules under `modules/`

This keeps CI detached from remote state and AWS credentials while still verifying the real Terraform roots currently implemented in the repository.

The GitHub Actions OIDC role created by `bootstrap/dev` is reserved for future deployment workflows and is not used by the CI validation workflow.

---

## Design principles

- keep environments thin
- place reusable logic inside modules
- prefer secure-by-default designs
- separate platform, ingress, and workload responsibilities
- avoid deprecated Terraform resources and arguments
- keep the repository beginner-friendly and clearly documented

---

## Environments

- **dev** — fully demonstrated baseline environment
- **stage** — planned extension path
- **prod** — planned extension path

---

## Configuration

See environment-specific `*.tfvars` files in the `envs/` directories.




