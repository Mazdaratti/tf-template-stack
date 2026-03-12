# Production Environment

This folder is the planned Terraform root module for the `prod` environment.

It exists to show how the same reusable module pattern can be extended from the demonstrated `dev` baseline into a production environment with stricter resilience, change control, and operational requirements.

Current status:

- `envs/dev` is the fully demonstrated environment in this repository
- `envs/prod` is intentionally reserved as the long-term production extension path
- the production root module is not fully implemented yet

When this environment is implemented, it should follow the same architectural direction:

- thin root-module composition
- reusable modules from `modules/`
- private-by-default networking
- shared encryption, logging, and ingress baselines
- workload deployment through the ECS service layer

Production rollout would typically add stronger environment-specific controls, such as:

- higher availability defaults
- stricter IAM and policy review
- tighter change management
- stronger validation and deployment safeguards

For the current fully documented environment flow, see:

- `envs/dev/README.md`

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
