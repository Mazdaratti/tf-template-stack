resource "aws_iam_policy_attachment" "github_actions_admin" {
  count      = var.attach_admin_policy ? 1 : 0
  name       = "gh-oidc-${var.project_name}-${var.environment}-admin-attachment"
  roles      = [aws_iam_role.github_actions.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}