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