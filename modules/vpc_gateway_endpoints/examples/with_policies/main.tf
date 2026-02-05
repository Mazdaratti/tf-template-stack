provider "aws" {
  region = "eu-central-1"
}

############################################
# Minimal VPC + route table
############################################

resource "aws_vpc" "this" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project     = "gateway-endpoints-policy-example"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

############################################
# Resources used in endpoint policies
############################################

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "example" {
  bucket = "gateway-endpoints-policy-example-${random_id.suffix.hex}"
}

resource "aws_dynamodb_table" "example" {
  name = "gateway-endpoints-policy-example-${random_id.suffix.hex}"

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"
  attribute {
    name = "Id"
    type = "S"
  }
}

############################################
# Endpoint policies for S3 and DynamoDB
############################################

data "aws_iam_policy_document" "s3_endpoint" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      # In real projects, replace with:
      # module.s3_bucket.bucket_arn
      # or
      # var.s3_bucket_arn
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*"
    ]

    resources = [
      # In real projects, replace with:
      # module.dynamodb_table.table_arn
      # or
      # var.dynamodb_table_arn
      aws_dynamodb_table.example.arn
    ]
  }
}

############################################
# Module call
############################################

module "vpc_gateway_endpoints" {
  source = "../../"

  project_name = "gateway-endpoints-policy-example"
  environment  = "dev"

  vpc_id          = aws_vpc.this.id
  route_table_ids = [aws_route_table.private.id]

  gateway_endpoints = {
    s3       = true
    dynamodb = true
  }

  endpoint_policy_json = {
    s3       = data.aws_iam_policy_document.s3_endpoint.json
    dynamodb = data.aws_iam_policy_document.dynamodb_endpoint.json
  }
}