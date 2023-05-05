# Create and launch the EC2

resource "aws_instance" "web_server" {
  ami                         = "ami-0d76271a8a1525c1a"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  iam_instance_profile        = aws_iam_instance_profile.web_server_profile.name
  key_name                    = "webserver"
  vpc_security_group_ids      = [aws_security_group.ec2_webserver.id]
  user_data = templatefile("${path.module}/ec2_user_data.sh.tpl", {
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
