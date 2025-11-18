variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for storing Terraform state"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "availability_zones" {
  description = "The availability zones for the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t4g.nano"
}

variable "home_cidrs" {
  description = "List of optional IPv6 CIDR blocks for home"
  type        = list(string)
  default     = []  # If empty, no ingress rules will be added
}

variable "wireguard_client_public_key" {
  description = "Public key for the WireGuard peer"
  type        = string
}

variable "wireguard_server_private_key" {
  description = "Private key of the WireGuard server"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {
    "Environment" = "dev"
    "Project"     = "stalwart-wireguard-proxy"
  }
}
