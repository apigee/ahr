

data  "azurerm_subnet" "az_vnet_subnet" {
  name = var.az_vnet_subnet
  virtual_network_name = var.az_vnet

  resource_group_name = var.resource_group
}

output "az_vnet_subnet_id" {
  value = data.azurerm_subnet.az_vnet_subnet.id
}
