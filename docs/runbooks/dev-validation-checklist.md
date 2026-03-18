# Dev Validation Checklist

This runbook describes the manual end-to-end validation flow for the `dev`
environment.

It is intentionally procedural and focused on the operator lifecycle:

1. create bootstrap resources
2. sync GitHub Environment deployment wiring
3. deploy `envs/dev` through GitHub Actions
4. validate the deployed environment
5. destroy `envs/dev`
6. destroy `bootstrap/dev`

## Preconditions

- local AWS credentials are configured for the target account
- `gh auth login` has been completed
- bootstrap and environment documentation have been reviewed:
  - `bootstrap/dev/README.md`
  - `envs/dev/README.md`

## 1. Bootstrap apply

From `bootstrap/dev`:

```sh
terraform init
terraform apply
```

Verify:

- Terraform state bucket exists
- Terraform lock table exists
- GitHub OIDC provider exists
- GitHub Actions deploy role exists
- `envs/dev/backend.tf` was generated

## 2. Sync GitHub Environment variables

From the repository root:

```sh
python scripts/sync_github_env.py dev --dry-run
python scripts/sync_github_env.py dev
```

Verify GitHub Environment `dev` contains:

- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`
- `TF_BACKEND_DYNAMODB_TABLE`
- `TF_BACKEND_KEY`

## 3. Deploy `envs/dev`

Trigger the manual GitHub Actions workflow:

- `Deploy Dev Environment`

Verify the workflow passes:

- AWS credentials configuration
- Terraform init
- Terraform validate
- Terraform plan
- Terraform apply
- ECS service stability wait
- target group health verification

## 4. Validate deployed infrastructure

Verify in AWS:

- ECS cluster exists
- ECS service is stable
- ALB target group has healthy targets
- expected network, logging, storage, and DNS resources exist

## 5. Destroy `envs/dev`

From `envs/dev`:

```sh
terraform init
terraform destroy -var-file=dev.tfvars
```

Verify environment resources are removed cleanly.

## 6. Destroy `bootstrap/dev`

From `bootstrap/dev`:

```sh
terraform destroy
```

Verify:

- Terraform state bucket is removed
- Terraform lock table is removed
- no manual bucket cleanup is required

## Recovery note

If `bootstrap/dev` is destroyed before `envs/dev`:

1. recreate `bootstrap/dev`
2. remove the existing `.terraform` directory in `envs/dev`
3. re-run `terraform init` in `envs/dev`
