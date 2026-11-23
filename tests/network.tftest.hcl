mock_provider "azurerm" {
  override_resource {
    target = azurerm_subnet.management
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tf-win-network-lab/providers/Microsoft.Network/virtualNetworks/vnet-win-lab/subnets/snet-management"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tf-win-network-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tf-win-network-lab/providers/Microsoft.Network/publicIPAddresses/pip-win-lab"
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tf-win-network-lab/providers/Microsoft.Network/networkInterfaces/nic-win-lab"
    }
  }
}

variables {
  rdp_source_cidr   = "203.0.113.10/32"
  vm_admin_password = "TerraformMockOnly42!"
}

run "regional_network_associations" {
  command = apply

  assert {
    condition = (
      azurerm_virtual_network.lab.location == "germanywestcentral" &&
      azurerm_network_interface.windows.location == azurerm_virtual_network.lab.location &&
      azurerm_windows_virtual_machine.lab.location == azurerm_virtual_network.lab.location &&
      azurerm_public_ip.windows.location == azurerm_virtual_network.lab.location &&
      azurerm_network_security_group.management.location == azurerm_virtual_network.lab.location
    )
    error_message = "La red, el NSG, la IP pública, la NIC y la VM deben estar en la misma región."
  }

  assert {
    condition = (
      azurerm_subnet.management.address_prefixes[0] == "10.20.1.0/24" &&
      azurerm_subnet.workload.address_prefixes[0] == "10.20.2.0/24"
    )
    error_message = "La VNet debe tener dos subredes con rangos distintos."
  }

  assert {
    condition = (
      azurerm_subnet_network_security_group_association.management.subnet_id == azurerm_subnet.management.id &&
      azurerm_subnet_network_security_group_association.management.network_security_group_id == azurerm_network_security_group.management.id &&
      azurerm_network_interface.windows.ip_configuration[0].subnet_id == azurerm_subnet.management.id &&
      azurerm_network_interface.windows.ip_configuration[0].public_ip_address_id == azurerm_public_ip.windows.id &&
      one(azurerm_windows_virtual_machine.lab.network_interface_ids) == azurerm_network_interface.windows.id
    )
    error_message = "El NSG, la subred, la NIC, la IP pública y la VM deben usar las asociaciones del laboratorio."
  }

  assert {
    condition     = azurerm_public_ip.windows.sku == "Standard" && azurerm_public_ip.windows.allocation_method == "Static"
    error_message = "La IP pública debe ser Standard y estática."
  }

  assert {
    condition = one([
      for rule in azurerm_network_security_group.management.security_rule : rule.source_address_prefix
      if rule.access == "Allow" && rule.direction == "Inbound" && rule.priority == 100 && rule.protocol == "Tcp" && rule.destination_port_range == "3389"
    ]) == var.rdp_source_cidr
    error_message = "Solo la IPv4 autorizada debe tener una regla de entrada para TCP 3389."
  }

  assert {
    condition = one([
      for rule in azurerm_network_security_group.management.security_rule : rule.source_address_prefix
      if rule.access == "Deny" && rule.direction == "Inbound" && rule.priority == 110 && rule.protocol == "*" && rule.destination_port_range == "3389"
    ]) == "*" && length(azurerm_network_security_group.management.security_rule) == 2
    error_message = "La segunda regla debe bloquear RDP desde los demás orígenes."
  }
}

run "zonal_network_plan" {
  command = plan

  variables {
    vm_zone = "2"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.lab.zone == "2" && one(azurerm_public_ip.windows.zones) == "2"
    error_message = "La VM y la IP pública deben compartir zona en un despliegue zonal."
  }
}

run "reject_open_rdp" {
  command = plan

  variables {
    rdp_source_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.rdp_source_cidr]
}

run "reject_weak_password" {
  command = plan

  variables {
    vm_admin_password = "sololetrasminusculas"
  }

  expect_failures = [var.vm_admin_password]
}
