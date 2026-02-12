output "key_arns" {
  description = "Map of key name => KMS key ARN."
  value       = module.kms_keys.key_arns
}

output "key_ids" {
  description = "Map of key name => KMS key ID."
  value       = module.kms_keys.key_ids
}

output "alias_names" {
  description = "Map of key name => KMS alias name."
  value       = module.kms_keys.alias_names
}

output "keys" {
  description = "Map of key name => object with key_arn, key_id, and alias_name."
  value       = module.kms_keys.keys
}
