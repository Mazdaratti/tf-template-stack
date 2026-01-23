config {
  module = true
  force  = false
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
  
  type {
    format = "snake_case"
  }
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}
