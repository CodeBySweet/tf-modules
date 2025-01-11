############## VPC ##############
resource "aws_vpc" "my-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

############## Public Subnets ##############
resource "aws_subnet" "public-subnet" {
  count             = length(var.subnet_name)
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.public_subnet_cidr_block[count.index]
  availability_zone = var.subnets_az[count.index]

  tags = {
    Name = "public-subnet-${var.subnet_name[count.index]}"
  }
}

############## Private Subnets ##############
resource "aws_subnet" "private-subnet" {
  count             = length(var.subnet_name)
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.private_subnet_cidr_block[count.index]
  availability_zone = var.subnets_az[count.index]

  tags = {
    Name = "private-subnet-${var.subnet_name[count.index]}"
  }
}

############## Internet Gateway ##############
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "igw"
  }
}

############## Public Route Table ##############
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "public-route-table"
  }
}

# Internet route in the public route table pointing to the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate the Public Route Table with a Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.subnet_name)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

############## NAT Gateway ##############
resource "aws_nat_gateway" "nat-igw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnet[0].id

  tags = {
    Name = "nat-gateway"
  }
}

# Elastic IP for the NAT Gateway
resource "aws_eip" "nat-eip" {
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-eip"
  }
}

############## Private Route Table ##############
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "private-route-table"
  }
}

# Route for outbound internet traffic in the private route table through the NAT Gateway
resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-igw.id
}

# Associate the Private Route Table with a Private Subnets
resource "aws_route_table_association" "private-1" {
  count          = length(var.subnet_name)
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

# Security Group for the VPC
resource "aws_security_group" "vpc-sg" {
  name        = "VPC-SG"
  description = "Homework-3 SG"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = var.security_group_name
    Env  = var.env
  }
}

# Inbound Rules for the Security Group
resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  count             = length(var.sg_ports)
  security_group_id = aws_security_group.vpc-sg.id
  cidr_ipv4         = aws_vpc.my-vpc.cidr_block
  from_port         = var.sg_ports[count.index]
  ip_protocol       = "tcp"
  to_port           = var.sg_ports[count.index]
}

# Security Group's Outbound Rules
resource "aws_vpc_security_group_egress_rule" "all_open" {
  security_group_id = aws_security_group.vpc-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}