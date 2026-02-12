############################################
# Local values
############################################
#
# Locals are internal helper values used to:
# - enforce consistent tagging
# - normalize user input
# - compute derived values (like alias names)
#
# They are NOT exposed outside the module.
#

locals {

  ############################################
  # 1. Enforced tags
  ############################################
  #
  # These tags are mandatory for all resources in this repository.
  # They ensure consistent tagging across all modules.
  #

  enforced_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ############################################
  # 2. Merged tags
  ############################################
  #
  # Merge enforced tags with user-provided common_tags.
  #
  # merge() order matters:
  # - Later values override earlier ones.
  #
  # Here:
  #   enforced_tags  → always present
  #   var.common_tags → can add additional tags
  #

  merged_tags = merge(
    local.enforced_tags,
    var.common_tags
  )

  ############################################
  # 3. Alias prefix
  ############################################
  #
  # If alias_prefix is provided → use it.
  # Otherwise → default to "project-environment".
  #
  # coalesce() returns the first non-null value.
  #

  alias_prefix = coalesce(
    var.alias_prefix,
    "${var.project_name}-${var.environment}"
  )

  ############################################
  # 4. Key normalization
  ############################################
  #
  # We iterate over the input map var.keys
  # and create a normalized internal structure.
  #
  # Why?
  # - To apply defaults safely
  # - To compute derived values like alias names
  # - To keep resource blocks clean
  #
  # try() allows safe access to optional attributes.
  #

  keys_normalized = {
    for key_name, cfg in var.keys : key_name => {

      # Optional fields with defaults
      description             = try(cfg.description, null)
      enable_key_rotation     = try(cfg.enable_key_rotation, true)
      deletion_window_in_days = try(cfg.deletion_window_in_days, 30)
      policy                  = try(cfg.policy, null)
      is_enabled              = try(cfg.is_enabled, true)
      multi_region            = try(cfg.multi_region, false)
      tags                    = try(cfg.tags, {})

      ########################################
      # Alias name logic
      ########################################
      #
      # If user explicitly provides alias_name → use it.
      #
      # Otherwise → automatically generate:
      #   alias/<prefix>-<key_name>
      #
      # Example:
      #   alias/tf-template-stack-dev-logs
      #

      effective_alias_name = coalesce(
        try(cfg.alias_name, null),
        "alias/${local.alias_prefix}-${key_name}"
      )
    }
  }
}
