# modules/ec2/variables.tf

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "wireguard-proxy"
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

variable "home_cidrs" {
  description = "List of optional CIDR blocks for allow access"
  type        = list(string)
  default     = []  # If empty, no ingress rules will be added
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}
