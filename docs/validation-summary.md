# Validation Summary

This repository was validated against a real AWS `dev` environment and a real
GitHub Actions deployment path.

## Validated capabilities

- `bootstrap/dev` apply succeeded
- `bootstrap/dev` destroy succeeded
- `bootstrap/dev` recreate flow succeeded
- local `envs/dev` apply succeeded
- local `envs/dev` destroy succeeded
- GitHub Actions `Deploy Dev Environment` workflow succeeded
- ECS service stability was verified
- ALB target-group health was verified

## What was exercised

### Bootstrap path

Validated in `bootstrap/dev`:

- remote backend bucket creation
- generated `envs/dev/backend.tf`
- GitHub OIDC provider creation
- GitHub Actions deploy-role creation
- teardown-friendly bootstrap lifecycle for `dev`

Reference:

- [`bootstrap/dev/README.md`](../bootstrap/dev/README.md)

### Environment path

Validated in `envs/dev`:

- VPC, subnets, route tables, and NAT
- gateway and interface endpoints
- KMS keys
- S3 storage baseline
- CloudWatch logging baseline
- VPC Flow Logs
- Route53 private zone
- ECS cluster
- internal ALB ingress
- ECS Fargate service

Reference:

- [`envs/dev/README.md`](../envs/dev/README.md)

### GitHub Actions path

Validated through the manually triggered deployment workflow:

- GitHub OIDC authentication
- Terraform `init`
- Terraform `validate`
- Terraform `plan`
- Terraform `apply`
- ECS service stability wait
- target-group health check

Reference:

- [dev-validation-checklist.md](./runbooks/dev-validation-checklist.md)

## Evidence

Evidence is included in:

- [`bootstrap/dev/README.md`](../bootstrap/dev/README.md)
- [`envs/dev/README.md`](../envs/dev/README.md)
- [`docs/screenshots/bootstrap-dev`](./screenshots/bootstrap-dev)
- [`docs/screenshots/envs-dev`](./screenshots/envs-dev)

## Current scope

- `dev` is the fully implemented and validated environment
- `stage` and `prod` remain extension paths only
- destroy is manual by design
- the ALB is internal, so workflow smoke checks use AWS-native health signals instead of external HTTP checks
