# modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "instance_security_group_id" {
  description = "The ID of the security group to associate with the EC2 instance"
  value       = aws_security_group.instance_sg.id
}
