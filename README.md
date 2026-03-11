# TF-Template-Stack

A modular Terraform configuration for deploying applications on AWS with environment-specific deployments.

## Structure

- **envs/**: Environment root modules (dev, stage, prod). Each env calls reusable modules.
- **modules/**: Reusable Terraform modules shared across environments.
- **bootstrap/** (optional): One-time prerequisites per environment (remote state, GitHub OIDC, IAM).
- **.vscode/**: Editor tasks/settings for repeatable workflows.

## Workflow

- Use VS Code tasks to run `fmt`, `tflint`, and `terraform-docs`.
- Generate docs for any env/module folder by opening a file in that folder and running:
  **terraform-docs: Generate README (current folder)**.

## Modules

- **network** — VPC + subnets + route tables (no NAT)
- **nat_gateway** — NAT Gateway(s) + private outbound routes
- **vpc_gateway_endpoints** — Gateway endpoints (S3, DynamoDB)
- **vpc_interface_endpoints** — Interface endpoints (PrivateLink services)
- **kms_keys** — Reusable KMS key creation with safe default policy
- **s3_bucket** — Secure-by-default S3 bucket with encryption, lifecycle, logging support
- **logging_baseline** — Shared CloudWatch Log Groups with standardized naming, retention, and optional KMS encryption
- **vpc_flow_logs** — Enables VPC Flow Logs delivery to a shared CloudWatch Log Group
- **route53_private_zones** — Private Route53 hosted zones with multi-VPC associations and optional baseline records
- **ecs_cluster** — ECS cluster baseline with optional container insights/capacity provider strategy and ECS Exec controls
- **alb_ingress** — Shared Application Load Balancer ingress baseline with security groups, listeners, target groups, and optional access logs
- **ecs_fargate_service** — Reusable ECS Fargate service baseline with task definition, service, IAM roles, service security group, optional CloudWatch logging, and optional existing target group attachment
- **remote_backend** — S3 + DynamoDB remote state backend (bootstrap use)

## Recommended order

1) `bootstrap/dev`  
   - Creates remote backend (S3 + DynamoDB)
   - Sets up GitHub OIDC / IAM (if used)

2) `envs/dev`  
   - Network baseline  
   - NAT Gateway  
   - VPC Endpoints  
   - KMS keys (encryption baseline)  
   - Storage baseline (S3 buckets)  
   - Logging baseline (CloudWatch Log Groups)  
   - VPC Flow Logs (network observability baseline)
   - Route53 private zones (private DNS baseline)
   - ECS cluster baseline (compute control plane)
   - ALB ingress baseline (shared ingress layer)
   - ECS Fargate service baseline (workload service layer)

## Environments

- **dev** - Development environment
- **stage** - Staging environment  
- **prod** - Production environment

## Configuration

See environment-specific `*.tfvars` files in `envs/` directories.




