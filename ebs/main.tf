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
# Create Instance Profile 
resource "aws_iam_instance_profile" "ebs_profile" {
  name = "EC2-EBS-Profile-TF"
  role = aws_iam_role.ebs_role.name
  tags = {
    Project = "App-portfolio"
  }
}

resource "aws_iam_role" "ebs_role" {
  name = "EC2-EBS-Role-TF"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Action" : [
          "cloudwatch:PutMetricData",
          "ec2:DescribeInstanceStatus",
          "s3:*"
        ]
        "resources" : ["*"]
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  ]

  tags = {
    Project = "App-portfolio"
  }
}
# TODO: Create eb app
# TODO: Create eb version
# TODO: Create eb environment
# TODO: setup output variable to give url for eb environment

variable "ecr_image" {
  type        = string
  description = "Docker image URL"
}