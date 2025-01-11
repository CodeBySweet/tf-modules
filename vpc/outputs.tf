# VPC ID
output "vpc_id" {
  value = aws_vpc.my-vpc.id
}

# Public Subnets IDs
output "public_subnet_ids" {
  value = aws_subnet.public-subnet[*].id
}

# Private Subnets IDs
output "private_subnet_ids" {
  value = aws_subnet.private-subnet[*].id
}