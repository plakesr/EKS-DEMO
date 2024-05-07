resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-VPC"
  })
}


# public -  10.10.0.0/20 | 10.10.16.0/20 |Ext 10.10.32.0/20
resource "aws_subnet" "public_subnet" {
  count             = length(local.public_subnet)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet[count.index]
  availability_zone = element(local.azs, count.index)
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-PUBLIC-SUBNET"
  })
}

# private - 10.10.64.0/19 | 10.10.96.0/19 |Ext 10.10.128.0/19
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnet)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet[count.index]
  availability_zone = element(local.azs, count.index)
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-PRIVATE-SUBNET"
  })
}

#IGW for Public
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-IGW"
  })
}

#NAT for public access single AZ
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-EIP-NAT"
  })
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-NAT"
  })
  depends_on = [aws_internet_gateway.gw]
}

#Route table -PublicSubnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-PUBLIC-RT"
  })
}

#PublicSubnet Assocaiation
resource "aws_route_table_association" "public_subnet_as" {
  count          = length(local.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

#Route for public subnet to outbound 
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

#Route table -PrivateSubnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.tags.Name}-PRIVATE-RT"
  })
}

#PublicSubnet Assocaiation
resource "aws_route_table_association" "private_subnet_as" {
  count          = length(local.private_subnet)
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

#Route for private subnet outbund 
resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.example.id
}

