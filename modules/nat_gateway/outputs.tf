output "mode" {
  description = "Effective NAT mode used by the module (per_az or single)."
  value       = var.mode
}

output "nat_gateway_ids" {
  description = "Map of NAT key => NAT Gateway ID. Keys are AZ names in per_az mode or 'single' in single mode."
  value       = { for k, ngw in aws_nat_gateway.this : k => ngw.id }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT key => public IP address of the NAT Gateway."
  value       = { for k, ngw in aws_nat_gateway.this : k => ngw.public_ip }
}

output "eip_allocation_ids" {
  description = "Map of NAT key => EIP allocation ID used by the NAT Gateway."
  value       = local.reuse_eips ? { for k in local.nat_keys : k => var.reuse_eip_allocation_ids[index(local.nat_keys, k)] } : { for k, e in aws_eip.nat : k => e.id }
}
