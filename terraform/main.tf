provider "aws" {
  region = var.region
}

module "vpc" {
  source              = "./modules/vpc"
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  home_cidrs          = var.home_cidrs
  tags                = var.tags
}

# Setup ssm module to store wireguard keys
module "ssm" {
  source                       = "./modules/ssm"
  wireguard_server_private_key = var.wireguard_server_private_key
  wireguard_client_public_key  = var.wireguard_client_public_key
  tags                         = var.tags
}

# Using the ec2 module to set up the launch template configurations
module "ec2" {
  source            = "./modules/ec2"
  instance_type     = var.instance_type
  instance_ami      = var.instance_ami
  tags              = var.tags
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.instance_security_group_id
}

# Auto Scaling Group with dynamic launch template version
resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = [module.vpc.public_subnet_ids[0]]
  launch_template {
    id      = module.ec2.launch_template_id
    version = module.ec2.launch_template_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
    triggers = ["tag"]
  }

  # Force new instances when the launch template changes
  tag {
    key = "LaunchTemplateVersion"
    # value               = data.aws_launch_template.latest.latest_version
    value               = module.ec2.launch_template_version
    propagate_at_launch = true
  }
}

# Elastic IP
resource "aws_eip" "ec2_eip" {
  tags = merge(var.tags, {
    "Name" = "wireguard-proxy"
  })
}

output "eip_id" {
  description = "The ID of the Elastic IP"
  value       = aws_eip.ec2_eip.id
}

output "eip_ip" {
  description = "The public IP of the Elastic IP"
  value       = aws_eip.ec2_eip.public_ip
}

module "s3_dynamodb" {
  source = "./modules/s3-dynamodb"

  s3_bucket_name = var.s3_bucket_name
  tags           = var.tags
}
