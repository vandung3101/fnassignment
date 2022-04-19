output "acr_name" {
  value = module.resources.admin_username
  sensitive = true
}

output "acr_password" {
  value = module.resources.admin_password
  sensitive = true
}