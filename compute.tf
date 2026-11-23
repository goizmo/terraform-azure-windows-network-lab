locals {
  vm_admin_username = "tfadmin"
}

resource "azurerm_windows_virtual_machine" "lab" {
  name                  = "vm-win-lab"
  location              = azurerm_network_interface.windows.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = var.vm_size
  zone                  = var.vm_zone
  admin_username        = local.vm_admin_username
  admin_password        = var.vm_admin_password
  network_interface_ids = [azurerm_network_interface.windows.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-g2"
    version   = "latest"
  }
}
