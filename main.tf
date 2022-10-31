
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}


# Query all avilable Availibility Zone
data "aws_availability_zones" "available" {}

# VPC Creation

resource "aws_vpc" "main1" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Nati-application-vpc"
  }
}

# Creating Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main1.id

  tags = {
    Name = "Nati-application-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Nati-application-public-route"
  }
}

# Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main1.default_route_table_id


  tags = {
    Name = "Nati-application-my-private-route-table"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = var.public_cidrs[count.index]
  vpc_id                  = aws_vpc.main1.id
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Nati-application-my-test-public-subnet.${count.index + 1}"
  }
}

# Public Subnet
#resource "aws_subnet" "public_subnet2" {
#  cidr_block              = "10.0.2.0/24"
#  vpc_id                  = aws_vpc.main1.id
#  map_public_ip_on_launch = true
# availability_zone       = "us-east-1a"

#  tags = {
#    Name = "Nati-application-my-test-public-subnet"
#  }
#}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = var.private_cidrs[count.index]
  vpc_id            = aws_vpc.main1.id
  availability_zone = "us-east-1b"

  tags = {
    Name = "Nati-application-my-test-private-subnet"
  }
}

# Private Subnet
#resource "aws_subnet" "private_subnet4" {
#  cidr_block        = "10.0.4.0/24"
#  vpc_id            = aws_vpc.main1.id
#  availability_zone = "us-east-1b"

#  tags = {
#    Name = "Nati-application-my-test-private-subnet"
#  }
#}

# Associate Public Subnet with Public Route  Table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 2
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Public Subnet with Public Route Table
#resource "aws_route_table_association" "public_subnet_assoc" {
#  route_table_id = aws_route_table.public_route.id
#  subnet_id      = aws_subnet.public_subnet2.id
#  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
#}
# Associate Private Subnet with Private Route  Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}

# Associate Private Subnet with Private Route 4 Table
#resource "aws_route_table_association" "private_subnet4_assoc" {
#  route_table_id = aws_default_route_table.private_route.id
#  subnet_id      = aws_subnet.private_subnet4.id
#  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
#}

# Security Group Creation
resource "aws_security_group" "test_sg" {
  name   = "my-test-sg"
  vpc_id = aws_vpc.main1.id
}

# Ingress Security Port 22
resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.test_sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.test_sg.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.test_sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_instance" "web-server" {
  ami                         = "ami-08c40ec9ead489470"
  instance_type               = "t2.micro"
  count                       = 2
  key_name                    = "chancetek"
  vpc_security_group_ids      = ["${aws_security_group.test_sg.id}"]
  subnet_id                   =  "subnet-02da3240c87eafad5"
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"

  user_data = <<-EOF
  #!/bin/bash
  sudo apt install apache2 -y
  sudo service apache2 start
  echo "Hello World V1" > /var/www/html/index.html
  EOF

  tags = {
    Name       = "Nati-application"
    Owner      = "nati"
    Department = "DevOps"
    Temp       = "True"
  }
}





