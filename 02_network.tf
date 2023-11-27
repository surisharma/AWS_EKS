# Production VPC
resource "aws_vpc" "production-vpc" {
   cidr_block = "10.0.0.0/16"
   enable_dns_support = true
   enable_dns_hostnames = true
}
# Public Subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = var.public_subnet_1_cidr
  availability_zone = var.available.names[0]
}
resource "aws_subnet" "public-subnet-2" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = var.public_subnet_2_cidr
  availability_zone = var.available.names[1]
}
# Private Subnets
resource "aws_subnet" "private-subnet-1" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = var.private_subnet_1_cidr
  availability_zone = var.available.names[0]
}
resource "aws_subnet" "private-subnet-2" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = var.private_subnet_2_cidr
  availability_zone = var.available.names[1]
}
# Router tables for the Subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id
}
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.production-vpc.id
}
# Associate the newly created route tables to the subnets
resource "aws_route_table_association" "public-route-1-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "public-route-2-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "private-route-1-association" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-route-table.id
}
resource "aws_route_table_association" "private-route-2-association" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-route-table.id
}
# Elastic IP
resource "aws_eip" "elastic-ip-for-nat1-gw" {
  vpc = true
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.production-igw]
}
resource "aws_eip" "elastic-ip-for-nat2-gw" {
  vpc = true
  associate_with_private_ip = "10.0.0.6"
  depends_on                = [aws_internet_gateway.production-igw]
}
# NAT Gateway
resource "aws_nat_gateway" "nat-gw1" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "gw NAT 1"
  }
  depends_on = [aws_eip.elastic-ip-for-nat-gw]
}
resource "aws_route" "nat-gw1-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw1.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_nat_gateway" "nat-gw2" {
  allocation_id = aws_eip.elastic-ip-for-nat2-gw.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "gw NAT 2"
  }
  depends_on = [aws_eip.elastic-ip-for-nat2-gw]
resource "aws_route" "nat-gw2-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw2.id
  destination_cidr_block = "0.0.0.0/0"
}
# Internet Gateway for the Public Subnet
resource "aws_internet_gateway" "production-igw" {
  vpc_id = "aws_vpc.production-vpc_id"
}

# Route the Public subnet traffic through the Internet Gateway
resource "aws_route" "public_internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}
