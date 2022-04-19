
resource "azurerm_virtual_network" "ansible-vnet" {
  name                = "ansible-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = var.location-1
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "ansible-subnet" {
  name                 = "ansible-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.ansible-vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_network_interface" "ansible-nic" {
  depends_on = [
    azurerm_subnet.ansible-subnet,
  ]
  name                = "ansible-nic"
  location            = var.location-1
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ansible-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_network" "main" {
  name                = "main"
  address_space       = ["11.0.0.0/8"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "gl-jk-subnet" {
  name                 = "gl-jk-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["11.1.0.0/16"]
}

resource "azurerm_subnet" "gateway-subnet" {
  name                 = "gateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["11.2.0.0/16"]
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gl-jk-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_peering" "peer1to3" {
  name                      = "peer1to3"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = azurerm_virtual_network.ansible-vnet.id
}

resource "azurerm_virtual_network_peering" "peer3to1" {
  name                      = "peer3to1"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.ansible-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.main.id
}

resource "azurerm_virtual_network" "aks" {
  name                = "aks"
  address_space       = ["10.0.0.0/8"]
  location            = var.location-2
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks-subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "postgres-rule-subnet" {
  name                 = "postgres-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.5.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}



resource "azurerm_virtual_network_peering" "appgw_aks_peering" {
  name                      = "appgw-aks-peer"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
}
resource "azurerm_virtual_network_peering" "aks_appgw_peering" {
  name                      = "aks-appgw-peer"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.main.id
}

resource "azurerm_public_ip" "gateway-public-ip" {
  name                = "gateway-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}