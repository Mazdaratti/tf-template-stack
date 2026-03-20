data "aws_iam_policy_document" "github_actions_state_permissions" {
  statement {
    sid    = "TerraformStateBucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"

    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "github_actions_state_policy" {
  name        = "gh-oidc-${var.project_name}-${var.environment}-state"
  description = "State backend access for GitHub Actions runs (S3 lockfile backend)."
  policy      = data.aws_iam_policy_document.github_actions_state_permissions.json

  tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Name        = "GitHub Actions Terraform State Policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_state" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_state_policy.arn
}
