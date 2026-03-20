output "tf_state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "tf_backend_key" {
  description = "Canonical backend state key used for the target environment."
  value       = local.tf_backend_key
}

output "aws_region" {
  description = "AWS region used for bootstrap resources and generated backend configuration."
  value       = var.aws_region
}

output "tf_state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role created for GitHub Actions OIDC."
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
