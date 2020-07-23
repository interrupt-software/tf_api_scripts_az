# Use this data source to access information about an existing Virtual Machine.
data "azurerm_virtual_machine" "azvm" {
  name                = azurerm_virtual_machine.azvm.name
  resource_group_name = azurerm_resource_group.azvm.name
}

output "virtual_machine_id" {
  value = data.azurerm_virtual_machine.azvm.id
}

output "virtual_machine_resource_group_name" {
  value = data.azurerm_virtual_machine.azvm.resource_group_name
}

# Use this data source to access information about an existing Network Security Group.
data "azurerm_network_security_group" "azvm" {
  name                = azurerm_network_security_group.azvm.name
  resource_group_name = azurerm_resource_group.azvm.name
}

output "azurerm_network_security_group_location" {
  value = data.azurerm_network_security_group.azvm.location
}

output "azurerm_network_security_group_security_rule" {
  value = data.azurerm_network_security_group.azvm.security_rule
}

# Use this data source to access information about an existing Public IP Address.
data "azurerm_public_ip" "azvm" {
  name                = azurerm_public_ip.azvm.name
  resource_group_name = azurerm_resource_group.azvm.name
}

output "azurerm_domain_name_label" {
  value = data.azurerm_public_ip.azvm.domain_name_label
}

output "azurerm_public_ip_address" {
  value = data.azurerm_public_ip.azvm.ip_address
}

# Create customized output for reference. In this case, a local variable and a data source.
output "ssh_command" {
  value = "ssh ${var.tfadmin}@${data.azurerm_public_ip.azvm.ip_address}"
}
