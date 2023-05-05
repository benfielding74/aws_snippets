variable "ecr_image" {
  type        = string
  description = "Docker image URL"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance type"
  default     = "t2.micro"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all projects"
  default = {
    "Created by" = "terraform"
    "Project"    = "app-portfolio"
  }
}