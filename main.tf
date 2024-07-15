# doormat aws tf-push --workspace terraform-ec2-neo4j --organization srahul3 --account 980777455695

# Define the provider
provider "aws" {
  region = "us-west-2"
}

# Create a new VPC
resource "aws_vpc" "neo4j_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "neo4j_vpc"
  }
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "neo4j_gw" {
  vpc_id = aws_vpc.neo4j_vpc.id
}

# Create a subnet
resource "aws_subnet" "neo4j_subnet" {
  vpc_id                  = aws_vpc.neo4j_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
}

# Create a security group
resource "aws_security_group" "neo4j_sg" {
  vpc_id = aws_vpc.neo4j_vpc.id
  name   = "neo4j_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "neo4j_sg" // may not be needed but good for human readability
  }
}

# Create an EC2 instance
resource "aws_instance" "neo4j_instance" {
  ami                         = "ami-0aff18ec83b712f05" # Update this to the latest Amazon Linux 2 AMI in your region
  instance_type               = "t2.large"
  subnet_id                   = aws_subnet.neo4j_subnet.id
  vpc_security_group_ids      = [aws_security_group.neo4j_sg.id]
  key_name                    = "nomad" # Specify the existing key pair name
  associate_public_ip_address = true    # Enable public IP

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y openjdk-11-jre-headless
              wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
              echo 'deb https://debian.neo4j.com stable 4.2' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
              sudo apt-get update -y
              sudo apt-get install -y neo4j=1:4.2.*
              sudo systemctl enable neo4j
              sudo systemctl start neo4j
              EOF

  tags = {
    Name = "Neo4jInstance"
  }
}

# Output the public IP of the EC2 instance
output "instance_public_ip" {
  value = aws_instance.neo4j_instance.public_ip
}
