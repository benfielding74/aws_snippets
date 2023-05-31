terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}

# set up an s3 public bucket to host a static web page

resource "aws_s3_bucket" "tf_web_example" {
  bucket = "tf-web-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "tf_web_example" {
  bucket = aws_s3_bucket.tf_web_example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "tf_web_example" {
  for_each = toset(["index.html", "error.html"])
  key      = each.key
  bucket   = aws_s3_bucket.tf_web_example.id
  source   = each.key
  content_type = "text/html"
}

# set public access policy

resource "aws_s3_bucket_ownership_controls" "tf_web_example" {
  bucket = aws_s3_bucket.tf_web_example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_web_example" {
  bucket = aws_s3_bucket.tf_web_example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "tf_web_example" {
  bucket = aws_s3_bucket.tf_web_example.id
  depends_on = [ 
    aws_s3_bucket_ownership_controls.tf_web_example,
    aws_s3_bucket_public_access_block.tf_web_example
   ]
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.tf_web_example.id
  depends_on = [ 
    aws_s3_bucket_ownership_controls.tf_web_example,
    aws_s3_bucket_public_access_block.tf_web_example
   ]
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal": "*",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.tf_web_example.arn}/*"
      }
    ]

  })
}

# tags

variable "tags" {
  type        = map(string)
  description = "Common tags for all projects"
  default = {
    "Created by" = "terraform"
    "Project"    = "test"
  }
}

# output the url
output "endpoint_url" {
  description = "Website endpoint"
  value       = aws_s3_bucket_website_configuration.tf_web_example.website_endpoint
}
