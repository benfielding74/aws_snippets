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
