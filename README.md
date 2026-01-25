# TF-Template-Stack

A modular Terraform configuration for deploying applications on AWS with environment-specific deployments.

## Structure

- **envs/**: Environment root modules (dev, stage, prod). Each env calls reusable modules.
- **modules/**: Reusable Terraform modules (copied/added as needed per project).
- **bootstrap/** (optional): One-time prerequisites per environment (remote state, GitHub OIDC, IAM).
- **.vscode/**: Editor tasks/settings for repeatable workflows.

## Workflow

- Use VS Code tasks to run `fmt`, `tflint`, and `terraform-docs`.
- Generate docs for any env/module folder by opening a file in that folder and running:
  **terraform-docs: Generate README (current folder)**.



<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Environments

- **dev** - Development environment
- **stage** - Staging environment  
- **prod** - Production environment

## Configuration

See environment-specific `*.tfvars` files in `envs/` directories.
