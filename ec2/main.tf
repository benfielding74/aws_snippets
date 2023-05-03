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

# Default vpc
data "aws_vpc" "default" {
  default = true
}

# Create the IAM roles and policies for the ec2 to pull from ECR
resource "aws_iam_role" "web_server_role" {
  name = "EC2WebServerRole-TF"

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
      }
    ]
  })

  tags = {
    Project = "WebServer"
  }
}

# policy

resource "aws_iam_policy" "ecr_policy" {
  name = "ECRImagePull-TF"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Sid" : "webserver",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        "Resource" : "arn:aws:ecr:eu-west-2:${var.account}:repository/app-portfolio"
      },
      {
        "Sid" : "webserver1",
        "Effect" : "Allow",
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_server_role" {
  role       = aws_iam_role.web_server_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "web_server_profile" {
  name = "webserver-profile-TF"
  role = aws_iam_role.web_server_role.name
}

#security group 
resource "aws_security_group" "ec2_webserver" {
  name        = "webserver-sg-tf"
  description = "Allow Web traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow ssh from my device"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "Allow http traffic from everywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "WebServer"
  }
}


# Create and launch the EC2

resource "aws_instance" "web_server" {
  ami                         = "ami-0d76271a8a1525c1a"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  iam_instance_profile        = aws_iam_instance_profile.web_server_profile.name
  key_name                    = "webserver"
  vpc_security_group_ids      = [aws_security_group.ec2_webserver.id]
  user_data                   = templatefile("${path.module}/ec2_user_data.sh.tpl", {
    VAR1 = var.ecr_repository
    VAR2 = var.ecr_image
  })

  tags = {
    Project = "Webserver"
    Name    = "webserver-TF"
  }

  depends_on = [aws_iam_role_policy_attachment.web_server_role]
}

#outputs

output "instance_public_ip" {
  value = aws_instance.web_server.public_dns
}

output "user_data" {
  value = aws_instance.web_server.user_data
}

#variables

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block for SSH access"
}

variable "ecr_image" {
  type = string
  description = "Docker image URL"
}

variable "ecr_repository" {
  type = string
  description = "ECR repository for docker log in" 
}

variable "account" {
  type = string
  description = "AWS account number"
  sensitive = true
}
