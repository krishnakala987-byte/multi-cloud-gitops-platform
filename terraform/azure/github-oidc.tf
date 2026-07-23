# Keyless CI on Azure: Entra ID app registration + federated credential.
# GitHub Actions logs in with azure/login@v2 using OIDC - zero client secrets.

data "azurerm_subscription" "current" {}

resource "azuread_application" "github" {
  display_name = "gha-${var.cluster_name}"
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
}

resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github.id
  display_name   = "github-main-branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:krishnakala987-byte@249091793/multi-cloud-gitops-platform@1310051356:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.github.id
  display_name   = "github-pull-requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:krishnakala987-byte@249091793/multi-cloud-gitops-platform@1310051356:pull_request"
}

# Reader on the resource group is enough for CI validate/plan.
resource "azurerm_role_assignment" "github_reader" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github.object_id
}
