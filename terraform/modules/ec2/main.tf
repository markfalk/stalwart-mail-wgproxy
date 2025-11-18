# Get the latest Amazon Linux 2023 ARM64 AMI in your region
data "aws_ami" "al2023_arm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-kernel-6.1-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  owners = ["amazon"]
}

# Create a Launch Template
resource "aws_launch_template" "ec2_launch_template" {
  name_prefix   = "ec2-asg-launch-template"
  image_id      = data.aws_ami.al2023_arm.id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 3
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false # we will manage the EIP later
    ipv6_address_count          = 1
    subnet_id                   = var.public_subnet_id
    security_groups             = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { "Name" = "wireguard-proxy" })
  }

  # Attach IAM role for SSM if needed
  iam_instance_profile {
    name = aws_iam_instance_profile.wp_instance_profile.name
  }

  # User data script to associate the EIP (Amazon Linux 2023)
  user_data = base64encode(file("modules/ec2/userdata.sh"))
}

resource "aws_iam_instance_profile" "wp_instance_profile" {
  name = "ec2_wp_instance_profile"
  role = aws_iam_role.wp_role.name
}

# Attach SSM IAM role to the instance (Optional)
resource "aws_iam_role" "wp_role" {
  name = "ec2_wp_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "wp_ssm_attach" {
  role       = aws_iam_role.wp_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ec2_eni_policy" {
  name        = "ec2_eni_policy"
  description = "Policy for associating an Elastic IP to an ENI"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeAddresses"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "wp_eni_attach" {
  role       = aws_iam_role.wp_role.name
  policy_arn = aws_iam_policy.ec2_eni_policy.arn
}

resource "aws_iam_policy" "ec2_ssm_ps_policy" {
  name = "ec2-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameterHistory"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/WireGuardConfig"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "wp_ssm_ps_attach" {
  role       = aws_iam_role.wp_role.name
  policy_arn = aws_iam_policy.ec2_ssm_ps_policy.arn
}


# Output the Launch Template ID
output "launch_template_id" {
  value = aws_launch_template.ec2_launch_template.id
}

# Output the Launch Template ID
output "launch_template_version" {
  value = aws_launch_template.ec2_launch_template.latest_version
}
