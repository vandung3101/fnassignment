output "ansible-nic-id" {
  value = azurerm_network_interface.ansible-nic.id
}

output "vm-nic-id" {
  value = azurerm_network_interface.nic.id
}

output "gateway-public-id" {
  value = azurerm_public_ip.gateway-public-ip.id
}

output "gateway-subnet-id" {
  value = azurerm_subnet.gateway-subnet.id
}

output "aks-subnet-id" {
  value = azurerm_subnet.aks-subnet.id
}

output "aks-vnet-id" {
  value = azurerm_virtual_network.aks.id
}

output "postgres-rule-subnet-id" {
  value = azurerm_subnet.postgres-rule-subnet.id
}
