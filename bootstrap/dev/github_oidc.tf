locals {
  github_repo_full_name = "${var.github_org}/${var.github_repo}"
  github_branch_subject = "repo:${local.github_repo_full_name}:ref:refs/heads/${var.github_branch}"
  github_env_subject    = "repo:${local.github_repo_full_name}:environment:${var.environment}"
  oidc_url              = "https://token.actions.githubusercontent.com"
}

# GitHub OIDC Provider (so the account can trust GitHub Actions tokens)
resource "aws_iam_openid_connect_provider" "github" {
  url             = local.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's OIDC thumbprint

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub-OIDC-Provider"
  })
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow only the repo-specific subject shapes that we actually use:
    # - branch-based runs for the configured branch
    # - environment-based runs for the configured GitHub Environment
    #
    # This stays tighter than a broad repo:* wildcard while supporting
    # the current deploy workflow, which runs with environment: dev.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        local.github_branch_subject,
        local.github_env_subject,
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "gh-oidc-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  # Attach permissions boundary only if we create it (see policy_boundary.tf)
  permissions_boundary = var.create_permissions_boundary ? aws_iam_policy.github_actions_boundary[0].arn : null

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub Actions OIDC Role"
  })
}


