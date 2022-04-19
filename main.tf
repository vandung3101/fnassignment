# To do
# Refactor main.tf >> modules
# Manual >> auto install ansible tower using remote-exec

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.2"
    }
  }
  backend "azurerm" {
    resource_group_name  = "default"
    storage_account_name = "tfstatevd"
    container_name       = "tfstate"
    # key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

module "keyvault" {
  source              = "./modules/keyvault"
  keyvault_name       = "terravd"
  resource_group_name = "default"
}

module "networks" {
  depends_on = [
    azurerm_resource_group.main
  ]
  source              = "./modules/networks"
  resource_group_name = "${var.prefix}-resources"
  location            = var.location
  location-1          = var.location-1
  location-2          = var.location-2
}

module "resources" {
  source              = "./modules/resources"
  resource_group_name = "${var.prefix}-resources"

  location                = var.location
  location-1              = var.location-1
  location-2              = var.location-2
  vm-username             = module.keyvault.vm-username
  ssh-pub-key             = module.keyvault.ssh-pub-key
  ssh-pri-key             = module.keyvault.ssh-pri-key
  db-username             = module.keyvault.db-username
  db-pass                 = module.keyvault.db-pass
  gateway-subnet-id       = module.networks.gateway-subnet-id
  ansible-nic-id          = module.networks.ansible-nic-id
  vm-nic-id               = module.networks.vm-nic-id
  gateway-public-id       = module.networks.gateway-public-id
  aks-subnet-id           = module.networks.aks-subnet-id
  aks-vnet-id             = module.networks.aks-vnet-id
  postgres-rule-subnet-id = module.networks.postgres-rule-subnet-id
}