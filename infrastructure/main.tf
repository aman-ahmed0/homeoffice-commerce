resource "azurerm_resource_group" "project" {
  name     = "rg-homeoffice-dev"
  location = var.location

  tags = {
    project     = "homeoffice-commerce"
    environment = "dev"
    purpose     = "portfolio"
  }
}

resource "azurerm_container_registry" "images" {
  name                = "hocommerce${substr(var.subscription_id, 0, 8)}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = azurerm_resource_group.project.tags
}

output "registry_login_server" {
  description = "Registry address used when tagging and pushing images."
  value       = azurerm_container_registry.images.login_server
}