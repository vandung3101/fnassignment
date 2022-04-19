resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.aks]
  filename     = "kubeconfig"
  content      = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "admin_password" {
  value       = azurerm_container_registry.acr.admin_password
}

output "admin_username" {
  value       = azurerm_container_registry.acr.admin_username
}