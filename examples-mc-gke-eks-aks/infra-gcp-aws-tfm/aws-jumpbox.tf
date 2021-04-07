

# aws: public subnet, igw, nat
resource "aws_subnet" "aws_public_subnet" {
  vpc_id     = aws_vpc.aws_vpc.id
  cidr_block = var.aws_public_cidr_block
  availability_zone = var.aws_zone_1

  map_public_ip_on_launch = true

  tags = {
    Name = var.aws_public_subnet
  }
}

resource "aws_internet_gateway" "aws_vpc_igw" {
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "aws-vpc-igw"
  }
}


# security: routes and security groups
# vpn gw for gcp vpc traffic
resource "aws_route" "aws_gcp_vpc_route" {
  route_table_id = aws_vpc.aws_vpc.default_route_table_id
  destination_cidr_block = var.gcp_vpc_cidr
  gateway_id = aws_vpn_gateway.aws_vpn_gw.id
}

resource "aws_vpn_connection_route" "aws-to-gcp" {
  destination_cidr_block = var.gcp_vpc_cidr
  vpn_connection_id = aws_vpn_connection.aws_gcp_vpn_connection.id
}


# Route: Internet traffic for jumpbox
resource "aws_route" "igw_traffic" {
  route_table_id = aws_vpc.aws_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.aws_vpc_igw.id
}

# Security Group: rule for 22 incoming
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [ "0.0.0.0/0" ]
  security_group_id = aws_vpc.aws_vpc.default_security_group_id
}


# aws: jumpbox
resource "aws_key_pair" "aws_pub_key" {
  key_name   = var.aws_key_name
  public_key = file(var.aws_ssh_pub_key_file)

}

resource "aws_instance" "aws-vm" {
  ami           = var.aws_image_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.aws_public_subnet.id
  key_name      = var.aws_key_name

  associate_public_ip_address = true

  tags = {
    Name = "aws-jumpbox"
  }
}

output "aws_jumpbox_ip" {
  value = aws_instance.aws-vm.public_ip
}
