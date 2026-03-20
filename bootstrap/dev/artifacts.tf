locals {
  tf_backend_key = "envs/${var.environment}/terraform.tfstate"
}

resource "local_file" "backend_config" {
  filename = "${path.module}/../../envs/${var.environment}/backend.tf"

  content = <<EOT
terraform {
  backend "s3" {
    bucket       = "${aws_s3_bucket.terraform_state.id}"
    key          = "${local.tf_backend_key}"
    region       = "${var.aws_region}"
    use_lockfile = true
  }
}
EOT
}
