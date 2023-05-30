# Create the VPC peering connection
resource "aws_vpc_peering_connection" "vpc_peering" {
  provider = aws

  peer_vpc_id = aws_vpc.database_vpc.id
  vpc_id      = aws_vpc.main_vpc.id

  # Allow traffic to flow between the VPCs
  auto_accept = true

  # Specify tags for the VPC peering connection
  tags = {
    Name = "my-vpc-peering-connection"
  }
}

# Update public route tables from MAIN to DATABASE
resource "aws_route" "main" {
  route_table_id            = aws_route_table.Main_public_route_table.id  # Replace with the ID of your public route table in your VPC
  destination_cidr_block    = aws_vpc.database_vpc.cidr_block  # Replace with the CIDR block of the peer VPC

  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id

}
# Update public route tables from DATABASE TO MAIN
resource "aws_route" "database" {
  route_table_id            = aws_route_table.Database_public_route_table.id  # Replace with the ID of your public route table in your VPC
  destination_cidr_block    = aws_vpc.main_vpc.cidr_block  # Replace with the CIDR block of the peer VPC

  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "main_private_route-1a" {
  route_table_id            = aws_route_table.Main_private_route_table_1a.id
  destination_cidr_block    = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "main_private_route-1b" {
  route_table_id            = aws_route_table.Main_private_route_table_1b.id
  destination_cidr_block    = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}


resource "aws_route" "database_private_route-2a" {
  route_table_id            = aws_route_table.Database_private_route_table_2a.id
  destination_cidr_block    = aws_vpc.main_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "database_private_route-2b" {
  route_table_id            = aws_route_table.Database_private_route_table_2b.id
  destination_cidr_block    = aws_vpc.main_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

