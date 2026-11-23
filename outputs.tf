output "resource_group_name" {
  description = "Grupo de recursos del laboratorio."
  value       = azurerm_resource_group.lab.name
}

output "vm_name" {
  description = "Nombre de la VM Windows."
  value       = azurerm_windows_virtual_machine.lab.name
}

output "public_ip_address" {
  description = "IPv4 pública de la NIC para RDP."
  value       = azurerm_public_ip.windows.ip_address
}

output "private_ip_address" {
  description = "IPv4 privada de la NIC en la subred de administración."
  value       = azurerm_network_interface.windows.private_ip_address
}

output "rdp_username" {
  description = "Usuario local que debes introducir en el cliente RDP."
  value       = ".\\${local.vm_admin_username}"
}
