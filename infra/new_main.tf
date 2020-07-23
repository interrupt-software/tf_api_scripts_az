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

resource "azurerm_virtual_machine" "main" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.azvm.name
  location            = azurerm_resource_group.azvm.location
  size                = "Standard_F2"
  network_interface_ids = [
    azurerm_network_interface.azvm.id,
  ]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
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
