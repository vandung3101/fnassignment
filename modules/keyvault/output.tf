output "vm-username" {
  value = data.azurerm_key_vault_secret.vm-username.value
}

output "ssh-pub-key" {
  value = data.azurerm_key_vault_secret.ssh-pub-key.value
}

output "ssh-pri-key" {
  value = data.azurerm_key_vault_secret.ssh-pri-key.value
}

output "db-username" {
  value = data.azurerm_key_vault_secret.db-username.value
}

output "db-pass" {
  value = data.azurerm_key_vault_secret.db-pass.value
}