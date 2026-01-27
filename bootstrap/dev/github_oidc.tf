locals {
  github_repo_full_name = "${var.github_org}/${var.github_repo}"
  github_subject        = "repo:${local.github_repo_full_name}:ref:refs/heads/${var.github_branch}"
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
      variable = "tocken.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Main branch restriction (or whatever branch is set to)
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "gh-oidc-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role

  # Attach permissions boundary only if we create it (see policy_boundary.tf)
  permissions_boundary = var.create_permissions_boundary ? aws_iam_policy.github_actions_boundary[0] : null

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub Actions OIDC Role"
  })
}


