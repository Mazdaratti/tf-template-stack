############################################
# Service log group
############################################
#
# This module owns the application log group used by the
# single ECS container definition in v1.
#
# Why keep it module-owned?
# - service logging stays self-contained
# - callers do not need to pre-create a per-service log group
# - KMS integration remains explicit through module inputs
#
# When logging is disabled, the log group is not created and
# the container definition omits the awslogs configuration.
############################################

resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_arn

  tags = local.merged_tags
}
