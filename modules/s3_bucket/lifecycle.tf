############################################
# S3 Lifecycle configuration (optional)
#
# Lifecycle rules let you automatically clean up objects:
# - delete objects after X days (expiration)
# - delete older versions after X days (noncurrent version expiration)
# - abort incomplete multipart uploads after X days (cleanup)
#
# IMPORTANT:
# - If you omit "filter", the rule applies to the whole bucket.
# - In AWS provider v5+, tags are supported only under filter.and.tags
############################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # We create this resource only if the user provided at least one rule.
  # If lifecycle_rules is empty, Terraform will not create anything.
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  # Each item in var.lifecycle_rules becomes one "rule" block.
  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      # A human-readable identifier for the rule (useful in AWS console too).
      id = rule.value.id

      # AWS expects "Enabled" / "Disabled" strings, but our variable uses a boolean.
      status = rule.value.enabled ? "Enabled" : "Disabled"

      ########################################
      # FILTERS (optional)
      #
      # Filters define which objects the rule applies to.
      # - prefix: applies to keys under a path-like prefix, e.g. "logs/"
      # - tags: applies only to objects that have these tags
      #
      # If neither prefix nor tags are provided, we do NOT create a filter at all,
      # and AWS applies the rule to the whole bucket.
      ########################################

      # Case 1: tags are provided
      #
      # In provider v5+, tags must be inside: filter { and { tags = ... } }
      # We also allow prefix together with tags inside the same "and" block.
      dynamic "filter" {
        for_each = try(rule.value.tags, null) != null ? [1] : []

        content {
          and {
            # prefix is optional (null is fine).
            prefix = try(rule.value.prefix, null)

            # tags is a map(string), e.g. { "category" = "logs" }
            tags = rule.value.tags
          }
        }
      }

      # Case 2: only prefix is provided (no tags)
      #
      # Here we can use the simpler filter form: filter { prefix = "logs/" }
      dynamic "filter" {
        for_each = (try(rule.value.tags, null) == null && try(rule.value.prefix, null) != null) ? [1] : []

        content {
          prefix = rule.value.prefix
        }
      }

      ########################################
      # ACTIONS (optional)
      #
      # Each action block is only created if the corresponding input is set.
      ########################################

      # Expire (delete) current objects after N days.
      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, null) != null ? [1] : []

        content {
          days = rule.value.expiration_days
        }
      }

      # Expire (delete) older versions after N days.
      # This is meaningful when versioning is enabled.
      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration_days, null) != null ? [1] : []

        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days
        }
      }

      # Abort incomplete multipart uploads after N days.
      # This helps avoid paying for abandoned multipart upload parts.
      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload_days, null) != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }
}
