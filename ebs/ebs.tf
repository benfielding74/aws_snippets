#  Create eb app
resource "aws_elastic_beanstalk_application" "app_portfolio" {
  name        = "app-portfolio-TF"
  description = "Testing deployment of apprentice portfolio"
  tags        = var.tags
}
# Create eb version
resource "aws_elastic_beanstalk_application_version" "app_portfolio_version" {
  name        = sha256(local_file.docker_run_config.content)
  application = aws_elastic_beanstalk_application.app_portfolio.name
  description = "Application version created by Terraform"
  bucket      = module.s3_bucket.s3_bucket_id
  key         = aws_s3_object.dockerrun_object.id
  tags        = var.tags
}
# Create eb environment
resource "aws_elastic_beanstalk_environment" "app_portfolio_environment" {
  name          = "app-portfolio-env-tf"
  application   = aws_elastic_beanstalk_application.app_portfolio.name
  platform_arn  = "arn:aws:elasticbeanstalk:eu-west-2::platform/Docker running on 64bit Amazon Linux 2/3.5.7"
  version_label = aws_elastic_beanstalk_application_version.app_portfolio_version.name
  cname_prefix  = "app-portfolio"
  tags          = var.tags

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ebs_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 2
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = 200
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }
}
# setup output variable to give url for eb environment
output "endpoint_url" {
  description = "CName endpoint to the EBS env"
  value       = aws_elastic_beanstalk_environment.app_portfolio_environment.cname
}
