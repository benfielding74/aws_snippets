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

# Create Dockerun config file
resource "local_file" "docker_run_config" {
  content = jsonencode({
    "AWSEBDockerrunVersion" : "1",
    "Image" : {
      "Name" : "${var.ecr_image}"
    },
    "Ports" : [
      {
        "ContainerPort" : 80
      }
    ]
  })
  filename = "${path.module}/Dockerrun.aws.json"
}
# Compress the Dockerun config file

data "archive_file" "docker_run" {
  type        = "zip"
  source_file = local_file.docker_run_config.filename
  output_path = "${path.module}/Dockerrun.aws.zip"
}

# Create s3 bucket to store config
# ACL's private
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "docker-run-bucket"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  tags = {
    Project = "App-portfolio"
  }
}
# Create S3 object from compressed Docker config

resource "aws_s3_object" "dockerrun_object" {
  bucket = module.s3_bucket.s3_bucket_id
  source = data.archive_file.docker_run.output_path
  key    = "${sha256(local_file.docker_run_config.content)}.zip"
  tags = {
    Project = "App-portfolio"
  }
}
# TODO: Create Instance Profile 
# TODO: Create eb app
# TODO: Create eb version
# TODO: Create eb environment
# TODO: setup output variable to give url for eb environment

variable "ecr_image" {
  type        = string
  description = "Docker image URL"
}