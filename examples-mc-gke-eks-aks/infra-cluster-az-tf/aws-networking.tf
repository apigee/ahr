
data "aws_vpc" "aws_vpc" {
  tags = {
    Name = var.aws_vpc
  }
}

data "aws_vpn_gateway" "aws_vpn_gw" {
  attached_vpc_id = data.aws_vpc.aws_vpc.id
  tags = {
    Name = var.aws_vpn_gw_name
  }
}

data "aws_route_table" "rtb_private_subnet" {
  vpc_id = data.aws_vpc.aws_vpc.id
  tags = {
    Name = "rtb-private-subnet"
  }
}

resource "aws_route" "aws_gcp_vpc_route" {
  route_table_id = data.aws_route_table.rtb_private_subnet.id

  destination_cidr_block = var.az_vnet_cidr
  gateway_id = data.aws_vpn_gateway.aws_vpn_gw.id
}
