# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  # version = "=2.0.0"
  features {}
}

resource "azurerm_resource_group" "azvm" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "azvm" {
  name                = "${var.prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azvm.location
  resource_group_name = azurerm_resource_group.azvm.name
}

resource "azurerm_subnet" "azvm" {
  name                 = "${var.prefix}-sn"
  resource_group_name  = azurerm_resource_group.azvm.name
  virtual_network_name = azurerm_virtual_network.azvm.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "azvm" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.azvm.location
  resource_group_name = azurerm_resource_group.azvm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azvm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azvm.id
  }
}

resource "azurerm_public_ip" "azvm" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.azvm.name
  location            = azurerm_resource_group.azvm.location
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "azvm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.azvm.name
  location            = azurerm_resource_group.azvm.location
  size                = "Standard_F2"
  admin_username      = var.tfadmin
  network_interface_ids = [
    azurerm_network_interface.azvm.id,
  ]

  admin_ssh_key {
    username   = var.tfadmin
    public_key = var.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "60"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "azvm" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.azvm.location
  resource_group_name = azurerm_resource_group.azvm.name
}

resource "azurerm_network_security_rule" "ssh_port" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azvm.name
  network_security_group_name = azurerm_network_security_group.azvm.name
}

resource "azurerm_network_security_rule" "tfe_https" {
  name                        = "TFE HTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azvm.name
  network_security_group_name = azurerm_network_security_group.azvm.name
}

resource "azurerm_network_security_rule" "tfe_dashboard" {
  name                        = "TFE Dashboard"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8800"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azvm.name
  network_security_group_name = azurerm_network_security_group.azvm.name
}
