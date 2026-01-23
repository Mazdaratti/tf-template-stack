config {
  call_module_type = "all"
  force  = false
}

plugin "terraform" {
  enabled = true
  version = "0.9.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

rule "terraform_naming_convention" {
  enabled = true
  
  variable {
    format = "snake_case"
  }
  
  locals {
    format = "snake_case"
  }
  
  output {
    format = "snake_case"
  }
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}
