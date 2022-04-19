data "azurerm_key_vault" "keyvault" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "vm-username" {
  name         = "vm-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ssh-pub-key" {
  name         = "ssh-pub-key"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ssh-pri-key" {
  name         = "ssh-pri-key"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "db-username" {
  name         = "db-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "db-pass" {
  name         = "db-pass"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}