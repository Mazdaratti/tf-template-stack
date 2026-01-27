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
      module.remote_backend.state_bucket_arn,
      "${module.remote_backend.state_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "TerraformLockTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      module.remote_backend.lock_table_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_state_policy" {
  name        = "gh-oidc-${var.project_name}-${var.environment}-state"
  description = "State backend access for GitHub Actions runs (S3 + DynamoDB)."
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