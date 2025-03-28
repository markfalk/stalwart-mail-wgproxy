# modules/ec2/variables.tf

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}

variable "instance_ami" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "public_subnet_id" {
  description = "The ID of the public subnet to launch the EC2 instance in"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the EC2 instance"
  type        = string
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}