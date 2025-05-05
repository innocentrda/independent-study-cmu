provider "aws" {
  region = "eu-west-2"
}

# Read existing public key from your local file
resource "aws_key_pair" "default" {
  key_name   = "pepc_id_rsa"
  public_key = file("~/msc/lab-keys/compute/pepc_id_rsa.pub") # Adjust path if needed
}

resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "instance_sg" {
  name        = "allow-all-sg"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-all-sg"
  }
}

resource "aws_instance" "web" {
  count                       = 10
  ami                         = "ami-0a94c8e4ca2674d5a"
  instance_type               = "t2.2xlarge"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.default.key_name

  tags = {
    Name = "web-${count.index}"
  }
}

# Output public and private IPs of the EC2 instances
output "instance_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = [for instance in aws_instance.web : instance.public_ip]
}

output "instance_private_ips" {
  description = "Private IPs of the EC2 instances"
  value       = [for instance in aws_instance.web : instance.private_ip]
}
