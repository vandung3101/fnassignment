
resource "azurerm_linux_virtual_machine" "ansible" {
  name                = "ansible"
  resource_group_name = var.resource_group_name
  location            = var.location-1
  size                = "Standard_DS3_v2"
  admin_username      = var.vm-username
  network_interface_ids = [
    var.ansible-nic-id,
  ]

  admin_ssh_key {
    username   = var.vm-username
    public_key = var.ssh-pub-key
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "8.5.2022012101"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

}

resource "azurerm_virtual_machine_extension" "install-ansible" {
  name                 = "install-ansible"
  virtual_machine_id   = azurerm_linux_virtual_machine.ansible.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<PROT
    {
        "script": "${base64encode(file("./install-awx.sh"))}"
    }
    PROT
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B4ms"
  admin_username      = var.vm-username
  network_interface_ids = [
    var.vm-nic-id,
  ]


  admin_ssh_key {
    username   = var.vm-username
    public_key = var.ssh-pub-key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}

resource "azurerm_application_gateway" "app-gateway" {
  depends_on = [
    azurerm_role_assignment.acrtoaks,
  ]
  name                = "gateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "app-gateway-ip"
    subnet_id = var.gateway-subnet-id
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "app-gateway-ip"
    public_ip_address_id = var.gateway-public-id
  }

  ssl_certificate {
    name     = "vandung-cert"
    data     = filebase64("./vandung.pfx")
    password = "123456"
  }

  trusted_root_certificate {
    name = "aks-root"
    data = filebase64("./isrgrootx1.cer")
  }

  backend_address_pool {
    name = "vm-pool"
    ip_addresses = [
      azurerm_linux_virtual_machine.vm.private_ip_address,
    ]
  }

  probe {
    name                = "probe-allow-403"
    host                = "jenkins.vandung.me"
    interval            = "15"
    protocol            = "Http"
    path                = "/"
    timeout             = "15"
    unhealthy_threshold = 3
    match {
      body        = ""
      status_code = ["403", "200-399"]
    }
  }

  backend_http_settings {
    name                  = "jenkins-settings"
    port                  = 8080
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 300
    probe_name            = "probe-allow-403"
  }


  http_listener {
    name                           = "jenkins.vandung.me"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "https"
    host_name                      = "jenkins.vandung.me"
    protocol                       = "Https"
    ssl_certificate_name           = "vandung-cert"
  }

  request_routing_rule {
    name                       = "jenkins-rule"
    rule_type                  = "Basic"
    http_listener_name         = "jenkins.vandung.me"
    backend_address_pool_name  = "vm-pool"
    backend_http_settings_name = "jenkins-settings"
  }

  http_listener {
    name                           = "gitlab.vandung.me"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = "gitlab.vandung.me"
    ssl_certificate_name           = "vandung-cert"
  }

  backend_http_settings {
    name                  = "gitlab-settings"
    port                  = 8082
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 300
  }

  request_routing_rule {
    name                       = "gitlab-rule"
    rule_type                  = "Basic"
    http_listener_name         = "gitlab.vandung.me"
    backend_address_pool_name  = "vm-pool"
    backend_http_settings_name = "gitlab-settings"
  }

  http_listener {
    name                           = "ansible.vandung.me"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = "ansible.vandung.me"
    ssl_certificate_name           = "vandung-cert"
  }

  backend_address_pool {
    name = "ansible-pool"
    ip_addresses = [
      azurerm_linux_virtual_machine.ansible.private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "ansible-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 300
  }

  request_routing_rule {
    name                       = "ansible-rule"
    rule_type                  = "Basic"
    http_listener_name         = "ansible.vandung.me"
    backend_address_pool_name  = "ansible-pool"
    backend_http_settings_name = "ansible-settings"
  }

  http_listener {
    name                           = "jenkins-http"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "jenkins.vandung.me"
  }

  http_listener {
    name                           = "gitlab-http"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "gitlab.vandung.me"
  }

  http_listener {
    name                           = "ansible-http"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "ansible.vandung.me"
  }

  request_routing_rule {
    name                       = "jenkins-http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "jenkins-http"
    backend_address_pool_name  = "vm-pool"
    backend_http_settings_name = "jenkins-settings"
  }

  request_routing_rule {
    name                       = "gitlab-http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "gitlab-http"
    backend_address_pool_name  = "vm-pool"
    backend_http_settings_name = "gitlab-settings"
  }

  request_routing_rule {
    name                       = "ansible-http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "ansible-http"
    backend_address_pool_name  = "ansible-pool"
    backend_http_settings_name = "ansible-settings"
  }


  backend_address_pool {
    name = "aks-pool"
    ip_addresses = [
      "10.0.1.200",
    ]
  }

  http_listener {
    name                           = "aks-https-listerner"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_names                     = ["frontend.vandung.me", "backend.vandung.me", "phppgadmin.vandung.me"]
    ssl_certificate_name           = "vandung-cert"
  }

  probe {
    name                = "aks-https-probe"
    host                = "phppgadmin.vandung.me"
    interval            = "15"
    protocol            = "Https"
    path                = "/"
    timeout             = "15"
    unhealthy_threshold = 3
    match {
      body        = ""
      status_code = ["200-399", "404", "502", "503"]
    }
  }


  backend_http_settings {
    name                           = "aks-https-settings"
    port                           = 443
    protocol                       = "Https"
    cookie_based_affinity          = "Disabled"
    request_timeout                = 300
    trusted_root_certificate_names = ["aks-root"]
    probe_name                     = "aks-https-probe"
  }

  request_routing_rule {
    name                       = "aks-rule"
    rule_type                  = "Basic"
    http_listener_name         = "aks-https-listerner"
    backend_address_pool_name  = "aks-pool"
    backend_http_settings_name = "aks-https-settings"
  }

  probe {
    name                = "aks-http-probe"
    host                = "phppgadmin.vandung.me"
    interval            = "15"
    protocol            = "Http"
    path                = "/"
    timeout             = "15"
    unhealthy_threshold = 3
    match {
      body        = ""
      status_code = ["200-399", "404", "502", "503"]
    }
  }
  backend_http_settings {
    name                  = "aks-http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 300
    probe_name            = "aks-http-probe"
  }

  http_listener {
    name                           = "aks-http-listerner"
    frontend_ip_configuration_name = "app-gateway-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_names                     = ["frontend.vandung.me", "backend.vandung.me", "phppgadmin.vandung.me"]
  }

  request_routing_rule {
    name                       = "aks-http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "aks-http-listerner"
    backend_address_pool_name  = "aks-pool"
    backend_http_settings_name = "aks-http-settings"
  }

}

resource "azurerm_postgresql_server" "db-service" {
  name                = "db-servicew678"
  location            = var.location-2
  resource_group_name = var.resource_group_name

  administrator_login          = var.db-username
  administrator_login_password = var.db-pass

  sku_name = "GP_Gen5_4"
  version  = "11"

  ssl_enforcement_enabled = true
}


resource "azurerm_postgresql_firewall_rule" "db-rule" {
  name                = "allow-all-azure"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.db-service.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_virtual_network_rule" "postgresql-vnet-rule" {
  name                                 = "aks-vnet-rule"
  resource_group_name                  = var.resource_group_name
  server_name                          = azurerm_postgresql_server.db-service.name
  subnet_id                            = var.postgres-rule-subnet-id
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_user_assigned_identity" "aks-identity" {
  name                = "aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location-2
}

resource "azurerm_role_assignment" "aks-role-assignment" {
  scope                = var.aks-subnet-id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-identity.principal_id
}
resource "azurerm_container_registry" "acr" {
  name                = "acrw678"
  resource_group_name = var.resource_group_name
  location            = var.location-2
  admin_enabled       = true
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks"
  location            = var.location-2
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks"
  kubernetes_version  = "1.21.9"
  default_node_pool {
    name                = "np"
    vm_size             = "Standard_D2_v2"
    enable_auto_scaling = true
    max_count           = 2
    min_count           = 1
    node_count          = 1
    vnet_subnet_id      = var.aks-subnet-id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks-identity.id,
    ]
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.0.4.0/24"
    dns_service_ip     = "10.0.4.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }
  tags = {
    Environment = "aks"
  }
}

resource "azurerm_storage_account" "waf-logs" {
  name                = "waflogs11110"
  resource_group_name = var.resource_group_name
  location            = var.location-2
  account_tier        = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_role_assignment" "acrtoaks" {
  depends_on = [
    azurerm_postgresql_virtual_network_rule.postgresql-vnet-rule,
  ]
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true

  provisioner "local-exec" {
    command = <<EOT
      chmod +x ./app/helm.sh
      ./app/helm.sh
    EOT
  }
}

resource "azurerm_dns_zone" "vandung" {
  name                = "vandung.me"
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_a_record" "vandung" {
  name                = "*"
  resource_group_name = var.resource_group_name
  zone_name           = azurerm_dns_zone.vandung.name
  ttl                 = 300
  target_resource_id  = var.gateway-public-id
}




