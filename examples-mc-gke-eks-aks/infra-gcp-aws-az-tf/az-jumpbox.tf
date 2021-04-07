


resource "azurerm_public_ip" "vm_az_pip" {
  name = "vm-az_pip"

  location = var.az_region
  resource_group_name = var.resource_group

  allocation_method   = "Dynamic"
}


data "azurerm_public_ip" "vm_az_pip_ref" {
  name = azurerm_public_ip.vm_az_pip.name
  resource_group_name = var.resource_group

  depends_on = [ azurerm_virtual_machine.vm_az ]
}

resource "azurerm_network_interface" "vm_az_nic" {
  name = "vm-az-nic"

  location = var.az_region
  resource_group_name = var.resource_group

  ip_configuration {
    name = "vm-az-ip"
    subnet_id = azurerm_subnet.az_vnet_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm_az_pip.id
  }
}

resource "azurerm_virtual_machine" "vm_az" {
  name = "vm-az"

  location = var.az_region
  resource_group_name = var.resource_group

  network_interface_ids = [ azurerm_network_interface.vm_az_nic.id ]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm-az-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = "vm-az"
    admin_username = var.az_username
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.az_username}/.ssh/authorized_keys"
      key_data =file(var.az_ssh_pub_key_file)
    }
  }
}
