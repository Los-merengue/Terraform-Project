provider "aws"{
    region = "us-east-1"
    access_key = #Input the security access_keys here
    secret_key = #Input the security Secret_access keys here

# Create a variable for IP address

variable "CIDR"{
  description = "Enter an IP Address For the CIDR Value"

}

# Create a VPC

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "Terraform-VPC"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "first-gw" {
  vpc_id = aws_vpc.first-vpc.id

  tags = {
    Name = "Terraform-igw"
  }
}

# Create Custom Route Table

resource "aws_route_table" "first-route-table" {
  vpc_id = aws_vpc.first-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.first-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.first-gw.id
  }

  tags = {
    Name = "Terraform-Route-Table"
  }
}

# Create Subnet

resource "aws_subnet" "First-Subnet" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = var.CIDR
  availability_zone = "us-east-1a"

  tags = {
    Name = "Terraform-Subnet"
  }
}

# Associate Subnet with Route Table 

resource "aws_route_table_association" "First-RA" {
  subnet_id      = aws_subnet.First-Subnet.id
  route_table_id = aws_route_table.first-route-table.id
}

# Create Security Group to allow port 22,80,443

resource "aws_security_group" "First-Web-SG" {
  name        = "allow_web_traffic"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.first-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Terraform-Web-SG"
  }
}

# Create a network interface with an IP in the subnet that was created in Step 4

resource "aws_network_interface" "First-NIC" {
  subnet_id       = aws_subnet.First-Subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.First-Web-SG.id]

}

# Assign an elastic IP to the network interface created in Step 2

resource "aws_eip" "First-EIP" {
  vpc                       = true
  network_interface         = aws_network_interface.First-NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.first-gw
  ]

 
  
}

# Create ubuntu server and install/enable apache2

# The below code are used to create the resource for terraform 
resource "aws_instance" "terraform-server" {
    ami = "ami-04505e74c0741db8d"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.First-NIC.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c "echo this is my first web server > /var/www/html/index.html"
                EOF

 
    tags = {
      Name = "Terraform-EC2-Instance"
    }

}

output "Public-EIP" {
  value = aws_eip.First-EIP.public_ip
}

output "Private-EIP" {
  value = aws_eip.First-EIP.private_ip
}
















