provider "aws" {
  profile = "default"
  region  = "sa-east-1"
}

resource "aws_key_pair" "spot_key" {
  key_name   = "spot_key"
  public_key = "${file("./id_rsa.pub")}"
}

resource "aws_vpc" "some_custom_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Some Custom VPC"
  }
}

resource "aws_subnet" "some_public_subnet" {
  vpc_id            = aws_vpc.some_custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "Some Public Subnet"
  }
}

resource "aws_subnet" "some_private_subnet" {
  vpc_id            = aws_vpc.some_custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "Some Private Subnet"
  }
}

resource "aws_internet_gateway" "some_ig" {
  vpc_id = aws_vpc.some_custom_vpc.id

  tags = {
    Name = "Some Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.some_custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.some_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.some_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.some_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.some_custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-0555c5c3b52744258"
  instance_type = "t2.micro"
  key_name      = "spot_key"

  subnet_id                   = aws_subnet.some_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = "${file("user_data.sh")}"

  tags = {
    "Name" : "PYTHON-HORUS-BACKEND"
  }
}