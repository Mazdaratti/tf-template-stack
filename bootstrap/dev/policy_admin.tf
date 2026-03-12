# Legacy / prototyping-only escape hatch
#
# This attachment is intentionally not part of the hardened
# deployment model for the repository.
#
# Keep it disabled by default and use it only for short-lived
# experimentation if you are deliberately trading security
# for speed during early bootstrap exploration.
#
# The recommended path is:
# - state access via policy_state.tf
# - deploy access via policy_deploy.tf
# - guardrails via policy_boundary.tf

resource "aws_iam_policy_attachment" "github_actions_admin" {
  count      = var.attach_admin_policy ? 1 : 0
  name       = "gh-oidc-${var.project_name}-${var.environment}-admin-attachment"
  roles      = [aws_iam_role.github_actions.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}
