
resource "aws_vpc" "myoffice" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ghana-office"
  }
}

resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.myoffice.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "public_sub" {
  vpc_id                  = aws_vpc.myoffice.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myoffice.id

  tags = {
    Name = "internet-gw"
  }
}

resource "aws_route_table" "rt_table" {
  vpc_id = aws_vpc.myoffice.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "internet-gw-route"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.rt_table.id
}
