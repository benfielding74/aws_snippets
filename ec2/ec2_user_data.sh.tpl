#!/bin/bash

# Install httpd and docker
sudo yum update -y
sudo yum install httpd docker -y

# Start and enable docker service
systemctl enable docker
systemctl start docker

# Start and enable HTTPD
systemctl enable httpd
systemctl start httpd

# Docker login, pull and run
sudo docker login -u AWS -p $(aws ecr get-login-password --region eu-west-2) ${VAR1}
sudo docker pull ${VAR2}
sudo docker run -d -p 8080:80 ${VAR2}

# Configure httpd with a proxy pass and proxy reverse
echo "ProxyPass / http://localhost:8080/" | sudo tee /etc/httpd/conf.d/proxy.conf
echo "ProxyPassReverse / http://localhost:8080/" | sudo tee -a /etc/httpd/conf.d/proxy.conf

# Restart httpd service
systemctl restart httpd

