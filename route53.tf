resource "aws_route53_zone" "db_private_zone" {
  name                 = "database.darwinbox.local"
  vpc {
    vpc_id             = aws_vpc.database_vpc.id  # Replace with your VPC ID
    vpc_region         = "ap-south-1"
  }
}

resource "aws_route53_record" "db_record1" {
  zone_id  = aws_route53_zone.db_private_zone.zone_id
  name     = "mongo-0.database.darwinbox.local"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.mongo-0.private_ip]  # Replace with the desired IP address
}

resource "aws_route53_record" "db_record2" {
  zone_id  = aws_route53_zone.db_private_zone.zone_id
  name     = "mongo-1.database.darwinbox.local"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.mongo-1.private_ip]  # Replace with the desired IP address
}

resource "aws_route53_record" "db_record3" {
  zone_id  = aws_route53_zone.db_private_zone.zone_id
  name     = "mongo-2.database.darwinbox.local"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.mongo-2.private_ip]  # Replace with the desired CNAME target
}
