# GitHub Actions permissions boundary (repo-aligned guardrail)
#
# Purpose in v1:
# - Keep the current bootstrap role model, where the boundary is attached
#   to the GitHub Actions role itself.
# - Prevent obvious IAM privilege escalation outside repo scope.
# - Still allow Terraform to manage the repo-owned IAM roles and policies
#   required by the currently implemented infrastructure.
#
# Notes:
# - This is still a pragmatic guardrail, not an enterprise-wide boundary.
# - The boundary is intentionally aligned to this repository's naming model.
# - Bootstrap resources remain manual even though the boundary does not
#   attempt to block every possible bootstrap-related action.

resource "aws_iam_policy" "github_actions_boundary" {
  count       = var.create_permissions_boundary ? 1 : 0
  name        = "gh-oidc-${var.project_name}-${var.environment}-boundary"
  description = "Repo-aligned permissions boundary for the GitHub Actions OIDC role."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllWithinBoundaryUnlessExplicitlyDenied"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyIAMPrivilegeEscalationOutsideRepoScope"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:UpdateUser"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyIAMManagementOutsideRepoOwnedRolesAndPolicies"
        Effect = "Deny"
        Action = [
          "iam:AttachRolePolicy",
          "iam:CreatePolicy",
          "iam:CreateRole",
          "iam:DeletePolicy",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:TagPolicy",
          "iam:TagRole",
          "iam:UntagPolicy",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy"
        ]
        NotResource = [
          "arn:aws:iam::*:role/${var.project_name}-${var.environment}-*",
          "arn:aws:iam::*:policy/${var.project_name}-${var.environment}-*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub Actions Permissions Boundary"
  })

}
