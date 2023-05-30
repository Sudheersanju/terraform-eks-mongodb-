# creating security groups
resource "aws_security_group" "mongodb-sg" {
  vpc_id = aws_vpc.database_vpc.id
  depends_on = [aws_route_table_association.database_public_association_1a]
# inbound rules
# httpd access from anywhere
ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# ssh access from anywhere
ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
# outbound rules
egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}


resource "tls_private_key" "pem-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "database_key_pair" {
  key_name   = "database-key"
  public_key = tls_private_key.pem-key.public_key_openssh
  depends_on = [aws_security_group.mongodb-sg]
}

output "private_key_pem" {
  value = tls_private_key.pem-key.private_key_pem
  sensitive = true
}

resource "null_resource" "copy" {
  provisioner "local-exec" {
  command = <<-EOT
    echo "${tls_private_key.pem-key.private_key_pem}" > database-key.pem
    chmod 400 database-key.pem
  EOT
 }
  depends_on = [aws_key_pair.database_key_pair]
}

resource "aws_instance" "bastion-host" {
  ami           = "ami-08e5424edfe926b43"
  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name      = aws_key_pair.database_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.mongodb-sg.id]  # Replace with the desired security group ID(s)
  subnet_id              = aws_subnet.database_vpc_public_subnet_1.id  # Replace with the desired subnet ID

  tags = {
    Name = "Bastion-host"
  }
  depends_on = [null_resource.copy]
}

resource "aws_instance" "mongo-0" {
  ami           = "ami-08e5424edfe926b43"
  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name      = aws_key_pair.database_key_pair.key_name 

  vpc_security_group_ids = [aws_security_group.mongodb-sg.id]  # Replace with the desired security group ID(s)
  subnet_id              = aws_subnet.database_vpc_private_subnet_1.id  # Replace with the desired subnet ID

  depends_on = [aws_instance.bastion-host]
  tags = {
    Name = "mongo-master"
  }
}

resource "aws_instance" "mongo-1" {
  ami           = "ami-08e5424edfe926b43"
  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name      = aws_key_pair.database_key_pair.key_name 

  vpc_security_group_ids = [aws_security_group.mongodb-sg.id]  # Replace with the desired security group ID(s)
  subnet_id              = aws_subnet.database_vpc_private_subnet_1.id  # Replace with the desired subnet ID

  depends_on = [aws_instance.bastion-host]
  tags = {
    Name = "mongo-node-1"
  }
}

resource "aws_instance" "mongo-2" {
  ami           = "ami-08e5424edfe926b43"
  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name      = aws_key_pair.database_key_pair.key_name 

  vpc_security_group_ids = [aws_security_group.mongodb-sg.id]  # Replace with the desired security group ID(s)
  subnet_id              = aws_subnet.database_vpc_private_subnet_1.id  # Replace with the desired subnet ID

  depends_on = [aws_instance.bastion-host]
  tags = {
    Name = "mongo-node-2"
  }
}

resource "null_resource" "export-pem" {
  provisioner "local-exec" {
    command = <<-EOT
      scp -o "StrictHostKeyChecking=no" -i "database-key.pem" "database-key.pem" ubuntu@${aws_instance.bastion-host.public_ip}:~
    EOT
    working_dir = "./"
  }
  depends_on = [aws_instance.mongo-0, aws_instance.mongo-1, aws_instance.mongo-2]
}

resource "null_resource" "install-mongo-0" {
  depends_on = [null_resource.export-pem]

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo apt-get update",
      "sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release",
      "curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg",
      "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "sudo apt update",
      "sudo apt install mongodb-org -y",
      "sudo apt-get install -y mongodb-org=5.0.9 mongodb-org-database=5.0.9 mongodb-org-server=5.0.9 mongodb-org-shell=5.0.9 mongodb-org-mongos=5.0.9 mongodb-org-tools=5.0.9",
      "echo 'mongodb-org hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-database hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-server hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-shell hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-mongos hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-tools hold' | sudo dpkg --set-selections",
      "sudo systemctl start mongod",
      "sudo systemctl enable mongod",
      "echo '${aws_instance.mongo-0.private_ip} mongod-primary' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-1.private_ip} mongo-node-1' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-2.private_ip} mongo-node-2' | sudo tee -a /etc/hosts",
      "sudo sed -i 's/^\\(\\s*bindIp:\\s*\\)127\\.0\\.0\\.1/\\1127.0.0.1,${aws_instance.mongo-0.private_ip}/' /etc/mongod.conf",
      "sudo sed -i '/^#replication:/a  replication:\\n   replSetName: Sanjucluster' /etc/mongod.conf",
      "sudo systemctl restart mongod",
      "sleep 5",
      "mongosh --eval 'rs.initiate()';"
    ]

    connection {
      type            = "ssh"
      user            = "ubuntu"
      private_key     = tls_private_key.pem-key.private_key_pem
      host            = aws_instance.mongo-0.private_ip
      bastion_host    = aws_instance.bastion-host.public_ip
    }
  }
}


resource "null_resource" "install-mongo-1" {
  depends_on = [null_resource.export-pem]

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo apt-get update",
      "sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release",
      "curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg",
      "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "sudo apt update",
      "sudo apt install mongodb-org -y",
      "sudo apt-get install -y mongodb-org=5.0.9 mongodb-org-database=5.0.9 mongodb-org-server=5.0.9 mongodb-org-shell=5.0.9 mongodb-org-mongos=5.0.9 mongodb-org-tools=5.0.9",
      "echo 'mongodb-org hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-database hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-server hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-shell hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-mongos hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-tools hold' | sudo dpkg --set-selections",
      "sudo systemctl start mongod",
      "sudo systemctl enable mongod",
      "echo '${aws_instance.mongo-0.private_ip} mongod-primary' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-1.private_ip} mongo-node-1' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-2.private_ip} mongo-node-2' | sudo tee -a /etc/hosts",
      "sudo sed -i 's/^\\(\\s*bindIp:\\s*\\)127\\.0\\.0\\.1/\\1127.0.0.1,${aws_instance.mongo-1.private_ip}/' /etc/mongod.conf",
      "sudo sed -i '/^#replication:/a  replication:\\n   replSetName: Sanjucluster' /etc/mongod.conf",
      "sudo systemctl restart mongod",
      "sleep 5"
    ]

    connection {
      type            = "ssh"
      user            = "ubuntu"
      private_key     = tls_private_key.pem-key.private_key_pem
      host            = aws_instance.mongo-1.private_ip
      bastion_host    = aws_instance.bastion-host.public_ip
    }
  }
}

resource "null_resource" "install-mongo-2" {
  depends_on = [null_resource.export-pem]

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo apt-get update",
      "sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release",
      "curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg",
      "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "sudo apt update",
      "sudo apt install mongodb-org -y",
      "sudo apt-get install -y mongodb-org=5.0.9 mongodb-org-database=5.0.9 mongodb-org-server=5.0.9 mongodb-org-shell=5.0.9 mongodb-org-mongos=5.0.9 mongodb-org-tools=5.0.9",
      "echo 'mongodb-org hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-database hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-server hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-shell hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-mongos hold' | sudo dpkg --set-selections",
      "echo 'mongodb-org-tools hold' | sudo dpkg --set-selections",
      "sudo systemctl start mongod",
      "sudo systemctl enable mongod",
      "echo '${aws_instance.mongo-0.private_ip} mongod-primary' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-1.private_ip} mongo-node-1' | sudo tee -a /etc/hosts",
      "echo '${aws_instance.mongo-2.private_ip} mongo-node-2' | sudo tee -a /etc/hosts",
      "sudo sed -i 's/^\\(\\s*bindIp:\\s*\\)127\\.0\\.0\\.1/\\1127.0.0.1,${aws_instance.mongo-2.private_ip}/' /etc/mongod.conf",
      "sudo sed -i '/^#replication:/a  replication:\\n   replSetName: Sanjucluster' /etc/mongod.conf",
      "sudo systemctl restart mongod",
      "sleep 5"
    ]

    connection {
      type            = "ssh"
      user            = "ubuntu"
      private_key     = tls_private_key.pem-key.private_key_pem
      host            = aws_instance.mongo-2.private_ip
      bastion_host    = aws_instance.bastion-host.public_ip
    }
  }
}

resource "null_resource" "mongo-node-add" {
  depends_on = [null_resource.install-mongo-0, null_resource.install-mongo-1, null_resource.install-mongo-2]

  provisioner "remote-exec" {
    inline = [
      "mongosh --eval 'rs.add(\"${aws_instance.mongo-1.private_ip}:27017\")';",
      "mongosh --eval 'rs.add(\"${aws_instance.mongo-2.private_ip}:27017\")';",
    ]

    connection {
      type         = "ssh"
      user         = "ubuntu"
      private_key  = tls_private_key.pem-key.private_key_pem
      host         = aws_instance.mongo-0.private_ip
      bastion_host = aws_instance.bastion-host.public_ip
    }
  }
}
