locals {
  project_name = "your_project"
  environment  = var.environment
  
  common_tags = merge(
    var.tags,
    {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )
}
