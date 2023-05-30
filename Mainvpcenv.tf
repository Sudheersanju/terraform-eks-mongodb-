# Create the  MAIN VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name ="Main-VPC"
  }
}

# Create the public subnets for MAIN VPC
resource "aws_subnet" "main_vpc_public_subnet_1" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name ="MainVpc-PublicSubnet-1"
  }
}

resource "aws_subnet" "main_vpc_public_subnet_2" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name ="MainVpc-PublicSubnet-2"
  }
}

# Create the private subnets for MAIN VPC
resource "aws_subnet" "main_vpc_private_subnet_1" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name ="MainVpc-PrivateSubnet-1"
  }
}

resource "aws_subnet" "main_vpc_private_subnet_2" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name ="MainVpc-PrivateSubnet-2"
  }
}
resource "aws_subnet" "main_vpc_private_subnet_3" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name ="Main_Private-Subnet-3"
  }
}

resource "aws_subnet" "main_vpc_private_subnet_4" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name ="Main_Private-Subnet-4"
  }
}


# Create the internet gateway for MAIN VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name ="Main_IGW"
  }
}

# Create the Elastic IPs for NAT gateways for MAIN VPC
resource "aws_eip" "nat_eip_1a" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip_1b" {
  domain = "vpc"
}


# Create the NAT gateways for main vpc
resource "aws_nat_gateway" "nat_gateway_1a" {
  allocation_id = aws_eip.nat_eip_1a.id
  subnet_id     = aws_subnet.main_vpc_public_subnet_1.id
  tags = {
    Name ="Main_NatGateway-1"
  }
}

resource "aws_nat_gateway" "nat_gateway_1b" {
  allocation_id = aws_eip.nat_eip_1b.id
  subnet_id     = aws_subnet.main_vpc_public_subnet_2.id
  tags = {
    Name ="Main_NatGateway-2"
  }
}

# Create the route tables for MAIN VPC
resource "aws_route_table" "Main_public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name ="Main_Public-RouteTable"
  }
}

resource "aws_route_table" "Main_private_route_table_1a" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name ="Main_private-routeTable-1"
  }
}

resource "aws_route_table" "Main_private_route_table_1b" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name ="Main_private-routeTable-2"
  }
}


# Create route for MAIN public IGW
resource "aws_route" "main_public_route" {
  route_table_id         = aws_route_table.Main_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# create route for main private NAT-GW
resource "aws_route" "main_private_route_1a" {
  route_table_id         = aws_route_table.Main_private_route_table_1a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_1a.id
}

# create route for main private NAT-GW
resource "aws_route" "main_private_route_1b" {
  route_table_id         = aws_route_table.Main_private_route_table_1b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_1b.id
}

# Associate route table with Public subnets

resource "aws_route_table_association" "main_public_association_1a" {
  subnet_id      = aws_subnet.main_vpc_public_subnet_1.id
  route_table_id = aws_route_table.Main_public_route_table.id
}


resource "aws_route_table_association" "main_public_association_1b" {
  subnet_id      = aws_subnet.main_vpc_public_subnet_2.id
  route_table_id = aws_route_table.Main_public_route_table.id
}

# Associate route table with Private subnets

resource "aws_route_table_association" "main_private_association_1a" {
  subnet_id      = aws_subnet.main_vpc_private_subnet_1.id
  route_table_id = aws_route_table.Main_private_route_table_1a.id
}

resource "aws_route_table_association" "main_private_association_1b" {
  subnet_id      = aws_subnet.main_vpc_private_subnet_2.id
  route_table_id = aws_route_table.Main_private_route_table_1a.id
}

resource "aws_route_table_association" "main_private_association_1c" {
  subnet_id      = aws_subnet.main_vpc_private_subnet_3.id
  route_table_id = aws_route_table.Main_private_route_table_1b.id
}

resource "aws_route_table_association" "main_private_association_1d" {
  subnet_id      = aws_subnet.main_vpc_private_subnet_4.id
  route_table_id = aws_route_table.Main_private_route_table_1b.id
}


