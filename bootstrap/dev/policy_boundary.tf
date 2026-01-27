# Example permissions boundary (starter)
# Purpose:
# - Demonstrate the concept of permission boundaries as a guardrail.
# - Add a basic deny list to reduce common "privilege escalation" paths.
#
# Notes:
# - This is NOT a complete enterprise-grade boundary.
# - Real orgs often use centrally managed boundaries and more comprehensive controls.
# - Keep it as an example and adapt when you know your exact IAM requirements.

resource "aws_iam_policy" "github_actions_boundary" {
  count       = var.create_permissions_boundary ? 1 : 0
  name        = "gh-oidc-${var.project_name}-${var.environment}-boundary"
  description = "Example permissions boundary for GitHub Actions OIDC role (starter guardrail)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyIAMPrivilegeEscalation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:PutUserPolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDirectPolicyEditsOnUsers"
        Effect = "Deny"
        Action = [
          "iam:DeleteUserPolicy",
          "iam:UpdateUser"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub Actions Permissions Boundary (Example)"
  })

}