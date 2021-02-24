
data "aws_vpc" "aws_vpc" {
  tags = {
    Name = "${var.aws_vpc}"
  }
}
data "aws_subnet" "aws_public_subnet" {

  tags = {
    Name = "${var.aws_public_subnet}"
  }
}

data "aws_vpn_gateway" "aws_vpn_gw" {
  attached_vpc_id = data.aws_vpc.aws_vpc.id
  tags = {
    Name = "${var.aws_vpn_gw_name}"
  }
}

data "aws_security_group" "aws_vpc_sg" {
  name = "default"
  vpc_id = data.aws_vpc.aws_vpc.id
}


# NAT Gateway
resource "aws_eip" "nat_gw_eip" {
  vpc      = true

  tags = {
    Name = "nat-eip-alloc"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = data.aws_subnet.aws_public_subnet.id

  tags = {
    Name = "vpn-natgateway"
  }
}

# route table for private subnets 
resource "aws_route_table" "rtb_private_subnet" {
  vpc_id = data.aws_vpc.aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  route {
    cidr_block = var.gcp_vpc_cidr
    gateway_id = data.aws_vpn_gateway.aws_vpn_gw.id
  }

  tags = {
    Name = "rtb-private-subnet"
  }
}


# private subnets for private EKS cluster
resource "aws_subnet" "aws_private_subnet_1" {
  vpc_id     = data.aws_vpc.aws_vpc.id
  cidr_block = var.aws_private_cidr_block_1
  availability_zone = var.aws_zone_1

  tags = {
    Name = var.aws_private_subnet_1
    "kubernetes.io/cluster/${var.cluster}" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}
resource "aws_route_table_association" "rtb_assoc_1" {
  subnet_id      = aws_subnet.aws_private_subnet_1.id
  route_table_id = aws_route_table.rtb_private_subnet.id
}

resource "aws_subnet" "aws_private_subnet_2" {
  vpc_id     = data.aws_vpc.aws_vpc.id
  cidr_block = var.aws_private_cidr_block_2
  availability_zone = var.aws_zone_2

  tags = {
    Name = var.aws_private_subnet_2
    "kubernetes.io/cluster/${var.cluster}" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}
resource "aws_route_table_association" "rtb_assoc_2" {
  subnet_id      = aws_subnet.aws_private_subnet_2.id
  route_table_id = aws_route_table.rtb_private_subnet.id
}


resource "aws_subnet" "aws_private_subnet_3" {
  vpc_id     = data.aws_vpc.aws_vpc.id
  cidr_block = var.aws_private_cidr_block_3
  availability_zone = var.aws_zone_3

  tags = {
    Name = var.aws_private_subnet_3
    "kubernetes.io/cluster/${var.cluster}" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}
resource "aws_route_table_association" "rtb_assoc_3" {
  subnet_id      = aws_subnet.aws_private_subnet_3.id
  route_table_id = aws_route_table.rtb_private_subnet.id
}

