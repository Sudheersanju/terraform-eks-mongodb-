# Configure the AWS provider
provider aws {
  region = "ap-south-1"
  access_key = ""
  secret_key = ""
}

# Create the  DATABASE VPC
resource "aws_vpc" "database_vpc" {
  cidr_block = "10.1.0.0/18"
  tags = {
    Name ="Database-VPC"
  }
}

# Create the public subnets DATABASE VPC
resource "aws_subnet" "database_vpc_public_subnet_1" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name ="Database_Public-subnet-1"
  }
}

resource "aws_subnet" "database_vpc_public_subnet_2" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name ="Database_public-subnet-2"
  }

}

# Create the private subnets for DATABSE VPC
resource "aws_subnet" "database_vpc_private_subnet_1" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name ="Database_private-subnet-1"
  }
}

resource "aws_subnet" "database_vpc_private_subnet_2" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.4.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name ="Database_private-subnet-2"
  }
}

resource "aws_subnet" "database_vpc_private_subnet_3" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.5.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name ="Database_private-subnet-3"
  }
}

resource "aws_subnet" "database_vpc_private_subnet-4" {
  vpc_id     = aws_vpc.database_vpc.id
  cidr_block = "10.1.6.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name ="Database_private-subnet-4"
  }
}

# Create the internet gateway for DATABASE VPC
resource "aws_internet_gateway" "database_igw" {
  vpc_id = aws_vpc.database_vpc.id
  tags = {
    Name ="Database_IGW"
  }
}

# Create the Elastic IPs for NAT gateways for DATABASE VPC
resource "aws_eip" "nat_eip_2a" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip_2b" {
  domain = "vpc"
}

# Create the NAT gateways for database vpc
resource "aws_nat_gateway" "nat_gateway_2a" {
  allocation_id = aws_eip.nat_eip_2a.id
  subnet_id     = aws_subnet.database_vpc_public_subnet_1.id
  tags = {
    Name ="Database_NAT-gateway-2a"
  }
}

resource "aws_nat_gateway" "nat_gateway_2b" {
  allocation_id = aws_eip.nat_eip_2b.id
  subnet_id     = aws_subnet.database_vpc_public_subnet_2.id
  tags = {
    Name ="Database_NAT-gateway-2b"
  }
}

# Create the route tables for DATABASE VPC
resource "aws_route_table" "Database_public_route_table" {
  vpc_id = aws_vpc.database_vpc.id
  tags = {
    Name ="Database_Public-RouteTable"
  }
}

resource "aws_route_table" "Database_private_route_table_2a" {
  vpc_id = aws_vpc.database_vpc.id
  tags = {
    Name ="DataBase_Private-RouteTable-1a"
  }
}

resource "aws_route_table" "Database_private_route_table_2b" {
  vpc_id = aws_vpc.database_vpc.id
  tags = {
    Name ="Database_Private_routeTable_1b"
  }
}

# Create route for DATABASE public IGW
resource "aws_route" "database_public_route" {
  route_table_id         = aws_route_table.Database_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.database_igw.id
}

# Create route for DATABASE private NAT-GW
resource "aws_route" "database_private_route_2a" {
  route_table_id         = aws_route_table.Database_private_route_table_2a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_2a.id
}

# Create route for DATABASE private NAT-GW
resource "aws_route" "database_private_route_2b" {
  route_table_id         = aws_route_table.Database_private_route_table_2b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_2b.id
}

# Associate route table with Database Public subnets

resource "aws_route_table_association" "database_public_association_1a" {
  subnet_id      = aws_subnet.database_vpc_public_subnet_1.id
  route_table_id = aws_route_table.Database_public_route_table.id
}


resource "aws_route_table_association" "database_public_association_1b" {
  subnet_id      = aws_subnet.database_vpc_public_subnet_2.id
  route_table_id = aws_route_table.Database_public_route_table.id
}

# Associate route table with  Database Private subnets

resource "aws_route_table_association" "database_private_association_1a" {
  subnet_id      = aws_subnet.database_vpc_private_subnet_1.id
  route_table_id = aws_route_table.Database_private_route_table_2a.id
}

resource "aws_route_table_association" "database_private_association_1b" {
  subnet_id      = aws_subnet.database_vpc_private_subnet_2.id
  route_table_id = aws_route_table.Database_private_route_table_2a.id
}

resource "aws_route_table_association" "database_private_association_1c" {
  subnet_id      = aws_subnet.database_vpc_private_subnet_3.id
  route_table_id = aws_route_table.Database_private_route_table_2b.id
}

resource "aws_route_table_association" "database_private_association_1d" {
  subnet_id      = aws_subnet.database_vpc_private_subnet-4.id
  route_table_id = aws_route_table.Database_private_route_table_2b.id
}



