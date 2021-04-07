

resource "azurerm_virtual_network" "az_vnet" {
  name = var.az_vnet
  location = var.az_region

  resource_group_name = var.resource_group
  address_space = [ var.az_vnet_cidr ]
}

resource "azurerm_subnet" "az_vnet_subnet" {
  name = var.az_vnet_subnet

  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.az_vnet.name

  address_prefixes = [ var.az_vnet_subnet_cidr ]
}



# Create the gateway subnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"

  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.az_vnet.name

  address_prefixes     = [ var.az_vnet_gw_subnet_cidr ]
}


#  Local network gateway 1
resource "azurerm_local_network_gateway" "az_gcp_lgw1" {
  name = var.az_gcp_lgw1_name

  resource_group_name = var.resource_group
  location = var.az_region

  gateway_address = google_compute_address.gcp_az_vpc_gw1_ip.address
  address_space = [ var.gcp_vpc_cidr ]
}

#  Local network gateway 2
resource "azurerm_local_network_gateway" "az_gcp_lgw2" {
  name = var.az_gcp_lgw2_name
  resource_group_name = var.resource_group

  location = var.az_region
  gateway_address = google_compute_address.gcp_az_vpc_gw1_ip.address
  address_space = [ var.gcp_vpc_cidr ]
}

# Azure: Request  Dynamic Public IP addresses
resource "azurerm_public_ip" "az_gcp_vnet_gw_ip1" {
  name = var.az_gcp_vnet_gw_ip1_name

  resource_group_name = var.resource_group
  location = var.az_region

  allocation_method = "Dynamic"
}

data "azurerm_public_ip" "az_gcp_vnet_gw_ip1_ref" {
  name = azurerm_public_ip.az_gcp_vnet_gw_ip1.name
  resource_group_name = var.resource_group

  depends_on = [ azurerm_virtual_network_gateway.az_vnet_gw ]
}

resource "azurerm_public_ip" "az_gcp_vnet_gw_ip2" {
  name = var.az_gcp_vnet_gw_ip2_name

  resource_group_name = var.resource_group
  location = var.az_region

  allocation_method = "Dynamic"
}

data "azurerm_public_ip" "az_gcp_vnet_gw_ip2_ref" {
  name = azurerm_public_ip.az_gcp_vnet_gw_ip2.name
  resource_group_name = var.resource_group

  depends_on = [ azurerm_virtual_network_gateway.az_vnet_gw ]
}

# Azure: Create the VPN gateway with Active-Active Configuration
resource "azurerm_virtual_network_gateway" "az_vnet_gw" {
  name = var.az_vnet_gw

  location = var.az_region
  resource_group_name = var.resource_group

  type = "Vpn"
  vpn_type = "RouteBased"
  sku = "VpnGw1"

  active_active = true

  ip_configuration {
    name = "gw-ip1"
    public_ip_address_id = azurerm_public_ip.az_gcp_vnet_gw_ip1.id
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  ip_configuration {
    name = "gw-ip2"
    public_ip_address_id = azurerm_public_ip.az_gcp_vnet_gw_ip2.id
    subnet_id = azurerm_subnet.gateway_subnet.id
  }
}

# Azure: Create the VPN connections
resource "random_id" "az_psk1" {
  byte_length = 24
}

resource "azurerm_virtual_network_gateway_connection" "az_gcp_vnet_to_vpc1" {
  name = "az-gcp-vnet-to-vpc1"
  location = var.az_region
  resource_group_name = var.resource_group
  
  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.az_vnet_gw.id
  local_network_gateway_id = azurerm_local_network_gateway.az_gcp_lgw1.id

  shared_key = random_id.az_psk1.b64_std
}

resource "random_id" "az_psk2" {
  byte_length = 24
}

resource "azurerm_virtual_network_gateway_connection" "az_gcp_vnet_to_vpc2" {
  name = "az-gcp-vnet-to-vpc2"
  location = var.az_region
  resource_group_name = var.resource_group
  
  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.az_vnet_gw.id
  local_network_gateway_id = azurerm_local_network_gateway.az_gcp_lgw2.id

  shared_key = random_id.az_psk2.b64_std
}
