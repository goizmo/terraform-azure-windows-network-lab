resource "azurerm_resource_group" "lab" {
  name     = "rg-tf-win-network-lab"
  location = var.region
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-win-lab"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "management" {
  name                            = "snet-management"
  resource_group_name             = azurerm_resource_group.lab.name
  virtual_network_name            = azurerm_virtual_network.lab.name
  address_prefixes                = ["10.20.1.0/24"]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "workload" {
  name                            = "snet-workload"
  resource_group_name             = azurerm_resource_group.lab.name
  virtual_network_name            = azurerm_virtual_network.lab.name
  address_prefixes                = ["10.20.2.0/24"]
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "management" {
  name                = "nsg-management"
  location            = azurerm_virtual_network.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "Allow-RDP-From-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.rdp_source_cidr
    destination_address_prefix = azurerm_subnet.management.address_prefixes[0]
  }

  security_rule {
    name                       = "Deny-Other-RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.management.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_public_ip" "windows" {
  name                = "pip-win-lab"
  location            = azurerm_virtual_network.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.vm_zone == null ? null : [var.vm_zone]
}

resource "azurerm_network_interface" "windows" {
  name                = "nic-win-lab"
  location            = azurerm_virtual_network.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows.id
  }

  # La subred queda protegida antes de conectarle la NIC con IP pública.
  depends_on = [azurerm_subnet_network_security_group_association.management]
}
