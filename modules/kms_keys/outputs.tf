############################################
# Outputs
############################################
#
# We return maps keyed by the same key names
# used in var.keys (e.g., logs, s3, ebs).
#
# If var.keys = {} then these outputs are
# empty maps, which is safe for consumers.
#

output "key_arns" {
  description = "Map of key name => KMS key ARN."
  value = {
    for name, res in aws_kms_key.this : name => res.arn
  }
}

output "key_ids" {
  description = "Map of key name => KMS key ID."
  value = {
    for name, res in aws_kms_key.this : name => res.key_id
  }
}

output "alias_names" {
  description = "Map of key name => KMS alias name."
  value = {
    for name, res in aws_kms_alias.this : name => res.name
  }
}

output "keys" {
  description = "Map of key name => object with key_arn, key_id, and alias_name."
  value = {
    for name in keys(aws_kms_key.this) : name => {
      key_arn    = aws_kms_key.this[name].arn
      key_id     = aws_kms_key.this[name].key_id
      alias_name = aws_kms_alias.this[name].name
    }
  }
}
