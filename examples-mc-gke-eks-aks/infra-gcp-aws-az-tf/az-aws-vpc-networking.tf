data "aws_vpc" "aws_vpc" {
  id = module.gcp_and_aws_infra.aws_vpc_id
}

data "aws_vpn_gateway" "aws_vpn_gw" {
  id = module.gcp_and_aws_infra.aws_vpn_gw_id
}

# AWS: 
resource "aws_customer_gateway" "aws_az_cgw" {
  bgp_asn = 65000
  ip_address = data.azurerm_public_ip.az_gcp_vnet_gw_ip1_ref.ip_address

  type = "ipsec.1"

  tags = {
    "Name" = var.aws_az_customer_gw
  }
}

resource "aws_vpn_connection" "aws_az_vpn_connection" {
  vpn_gateway_id = data.aws_vpn_gateway.aws_vpn_gw.id
  customer_gateway_id = aws_customer_gateway.aws_az_cgw.id

  type = "ipsec.1"
  static_routes_only  = true

  tags = {
    "Name" = var.aws_az_vpn_connection
  }
}

#  Azure: Local network gateway 1
resource "azurerm_local_network_gateway" "az_aws_lgw1" {
  name = var.az_local_gw1_name

  resource_group_name = var.resource_group
  location = var.az_region

  gateway_address = aws_vpn_connection.aws_az_vpn_connection.tunnel1_address
  address_space = [ var.aws_vpc_cidr ]
}

resource "azurerm_virtual_network_gateway_connection" "az_aws_vnet_to_vpc1" {
  name = "az-aws-vnet-to-vpc1"
  location = var.az_region
  resource_group_name = var.resource_group
  
  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.az_vnet_gw.id
  local_network_gateway_id = azurerm_local_network_gateway.az_aws_lgw1.id

  shared_key = aws_vpn_connection.aws_az_vpn_connection.tunnel1_preshared_key
}

#  Azure: Local network gateway 2
resource "azurerm_local_network_gateway" "az_aws_lgw2" {
  name = var.az_local_gw2_name

  resource_group_name = var.resource_group
  location = var.az_region

  gateway_address = aws_vpn_connection.aws_az_vpn_connection.tunnel2_address
  address_space = [ var.aws_vpc_cidr ]
}

resource "azurerm_virtual_network_gateway_connection" "az_aws_vnet_to_vpc2" {
  name = "az-aws-vnet-to-vpc2"
  location = var.az_region
  resource_group_name = var.resource_group
  
  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.az_vnet_gw.id
  local_network_gateway_id = azurerm_local_network_gateway.az_aws_lgw2.id

  shared_key = aws_vpn_connection.aws_az_vpn_connection.tunnel2_preshared_key
}

# AWS: routes
# vpn gw for gcp vpc traffic
resource "aws_route" "aws_az_vpc_route" {
  route_table_id = data.aws_vpc.aws_vpc.main_route_table_id

  destination_cidr_block = var.az_vnet_cidr
  gateway_id = data.aws_vpn_gateway.aws_vpn_gw.id
}

resource "aws_vpn_connection_route" "aws-to-az" {
  destination_cidr_block = var.az_vnet_cidr
  vpn_connection_id = aws_vpn_connection.aws_az_vpn_connection.id
}

