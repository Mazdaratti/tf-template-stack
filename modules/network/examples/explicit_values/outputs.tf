output "vpc_id" {
  value = module.network.vpc_id
}

output "azs" {
  value = module.network.azs
}

output "public_subnet_cidrs" {
  value = module.network.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  value = module.network.private_subnet_cidrs
}
