provider "aws" {
  profile = "yash"
  region  = "ap-south-1"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  depends_on = [aws_vpc.vpc]

  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "subnet_1"
  }
}

resource "aws_subnet" "subnet_2" {
  depends_on = [aws_vpc.vpc]

  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "subnet_2"
  }
}

resource "aws_internet_gateway" "IG" {
  depends_on = [aws_vpc.vpc]

  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "IG"
  }
}

resource "aws_route_table" "RT" {
  depends_on = [aws_internet_gateway.IG]

  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IG.id}"
  }

  tags = {
    Name = "RT"
  }
}

resource "aws_route_table_association" "subnet_1" {

  subnet_id      = "${aws_subnet.subnet_1.id}"
  route_table_id = "${aws_route_table.RT.id}"
}

resource "aws_security_group" "wpsg" {
  name        = "wpsg"
  description = "Allow SSH and http"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "wpsg"
  }
}

resource "aws_security_group" "mysqlsg" {
  name        = "mysqlsg"
  description = "Allow SSH and MySQL"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Mysql from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wpsg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysqlsg"
  }
}

resource "aws_instance" "wordpress" {

  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet_1.id}"
  vpc_security_group_ids = [aws_security_group.wpsg.id]
  key_name = "key2"

  tags = {
    Name = "wordpress"
  }
}

resource "aws_instance" "mysql" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet_2.id}"
  vpc_security_group_ids = [aws_security_group.mysqlsg.id]
  key_name = "key2"

  tags = {
    Name = "mysql"
  }
}

output "instance_ip_addr" {
  value = aws_instance.wordpress.public_dns
}

resource "null_resource" "CloudFront_Domain" {
  depends_on = [aws_instance.wordpress]

  provisioner "local-exec" {
    command = "chrome ${aws_instance.wordpress.public_dns}" 
  }
}