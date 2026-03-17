locals {
  tf_backend_key = "envs/${var.environment}/terraform.tfstate"
}

resource "local_file" "backend_config" {
  filename = "${path.module}/../../envs/${var.environment}/backend.tf"

  content = <<EOT
terraform {
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
    key            = "${local.tf_backend_key}"
    region         = "${var.aws_region}"
  }
}
EOT
}
