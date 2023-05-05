#variables

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block for SSH access"
}

variable "ecr_image" {
  type        = string
  description = "Docker image URL"
}

variable "ecr_repository" {
  type        = string
  description = "ECR repository for docker log in"
}

variable "account" {
  type        = string
  description = "AWS account number"
  sensitive   = true
}