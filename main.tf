# doormat aws tf-push --workspace terraform-ec2-neo4j --organization srahul3 --account 980777455695

# Define the provider
provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "neo4j_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.2.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create a security group
resource "aws_security_group" "neo4j_sg" {
  vpc_id = module.vpc.vpc_id
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
  subnet_id                   = module.vpc.public_subnets[0]
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

# Config update, change network binding
# Config file: /etc/neo4j/neo4j.conf
# edit and uncomment the following line
# dbms.default_listen_address=0.0.0.0
# default credentials: neo4j/neo4j

# Output the public IP of the EC2 instance
output "instance_public_ip" {
  value = aws_instance.neo4j_instance.public_ip
}
