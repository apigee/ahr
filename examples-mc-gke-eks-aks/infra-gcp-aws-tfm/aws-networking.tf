
resource "aws_vpc" "aws_vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = var.aws_vpc
  }
}

# vpn


# create and attach
resource "aws_vpn_gateway" "aws_vpn_gw" {
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = var.aws_vpn_gw_name
  }
}


resource "aws_customer_gateway" "aws_cgw" {
  bgp_asn = 65000
  ip_address = google_compute_address.gcp_vpn_ip.address
  type = "ipsec.1"

  tags = {
    "Name" = var.aws_gcp_customer_gw
  }
}


resource "aws_vpn_connection" "aws_gcp_vpn_connection" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_cgw.id
  type = "ipsec.1"
  static_routes_only  = true
  tags = {
    "Name" = var.aws_gcp_vpn_connection
  }
}


