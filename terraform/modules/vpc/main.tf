# Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true
  tags = merge(var.tags, {
    "Name" = var.vpc_name
  })
}

# Fetch all available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Extract only the first two AZs ending in 'a' and 'b'
locals {
  filtered_azs = [for az in data.aws_availability_zones.available.names : az if can(regex("${var.region}[a-b]$", az))]
}

# Use filtered AZs dynamically
locals {
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : local.filtered_azs
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)}"

  tags = merge(var.tags, {
    "Name" = "public-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

    tags = merge(var.tags, {
    "Name" = "${var.vpc_name}-public-route-table"
  })
}

# Associate the route table with public subnets
resource "aws_route_table_association" "public_subnet_assoc" {
  count = length(var.public_subnet_cidrs)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Fetch the IPv4 prefix list for EC2 Instance Connect
data "aws_ec2_managed_prefix_list" "eic_ipv4" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.region}.ec2-instance-connect"]
  }
}

# Fetch the IPv6 prefix list for EC2 Instance Connect
data "aws_ec2_managed_prefix_list" "eic_ipv6" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.region}.ipv6.ec2-instance-connect"]
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "ec2-instance-sg"
  description = "Allow WireGuard access"

  ingress {
    description = "Allow WireGuard"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # Consider narrowing this to specific IPs for better security
  }

  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    prefix_list_ids   = [
      data.aws_ec2_managed_prefix_list.eic_ipv4.id,
      data.aws_ec2_managed_prefix_list.eic_ipv6.id
    ]
    description       = "Allow traffic from EC2 Instance Connect"
  }

  dynamic "ingress" {
    for_each = var.home_cidrs
    content {
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      ipv6_cidr_blocks  = [ingress.value]  # Use each CIDR in the list
      description       = "Allow traffic from home IPv6"
    }
  }

  ingress {
    description = "Allow stalwart-mail HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider narrowing this to specific IPs for better security
  }

  ingress {
    description = "Allow stalwart-mail SMTP"
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow stalwart-mail SMTP"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow stalwart-mail SMTP"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow stalwart-mail IMAPS"
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow stalwart-mail managesieve"
    from_port   = 4190
    to_port     = 4190
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow DNS Queries"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow DNS Queries"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" = "InstanceSG"
  })
}
