variable "github_oidc_subject_repo" {
  description = "Repository part of the GitHub OIDC subject, in GitHub's immutable owner@id/repo@id format."
  type        = string
  default     = "aman-ahmed0@128940419/homeoffice-commerce@1261251392"
}

resource "azurerm_user_assigned_identity" "github_ci" {
  name                = "id-homeoffice-github-ci"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  tags = azurerm_resource_group.project.tags
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_ci.id
  issuer                    = "https://token.actions.githubusercontent.com"
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:${var.github_oidc_subject_repo}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_ci_acr_push" {
  scope                = azurerm_container_registry.images.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.github_ci.principal_id
  principal_type       = "ServicePrincipal"

  skip_service_principal_aad_check = true
}

output "github_ci_client_id" {
  value = azurerm_user_assigned_identity.github_ci.client_id
}

output "github_ci_tenant_id" {
  value = azurerm_user_assigned_identity.github_ci.tenant_id
}