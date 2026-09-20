variable "aks_admin_object_id" {
  description = "Object ID of the user who administers the showcase cluster."
  type        = string

  validation {
    condition = can(regex(
      "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
      var.aks_admin_object_id
    ))
    error_message = "Enter the user object ID returned by Azure CLI."
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "project" {
  name                = "aks-homeoffice-dev"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name
  node_resource_group = "rg-homeoffice-dev-nodes"
  dns_prefix          = "homeoffice-dev"

  kubernetes_version = "1.36.3"
  sku_tier           = "Free"
  support_plan       = "KubernetesOfficial"

  role_based_access_control_enabled = true
  local_account_disabled            = true
  node_os_upgrade_channel           = "NodeImage"

  node_provisioning_profile {
    mode               = "Manual"
    default_node_pools = "None"
  }

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D4as_v5"
    node_count           = 2
    auto_scaling_enabled = false
    os_sku               = "Ubuntu2404"
    os_disk_type         = "Managed"
    os_disk_size_gb      = 64
    max_pods             = 30
    zones                = ["1", "2"]

    upgrade_settings {
      max_surge = "1"
    }

    tags = azurerm_resource_group.project.tags
  }

  api_server_access_profile {
    authorized_ip_ranges = [var.admin_ipv4_cidr]
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    load_balancer_profile {
      managed_outbound_ip_count = 1
    }
  }

  tags = azurerm_resource_group.project.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.images.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.project.kubelet_identity[0].object_id
  principal_type       = "ServicePrincipal"

  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster_admin" {
  scope                = azurerm_kubernetes_cluster.project.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.aks_admin_object_id
  principal_type       = "User"
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.project.name
}

output "aks_resource_group_name" {
  value = azurerm_resource_group.project.name
}