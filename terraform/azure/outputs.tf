output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "gha_client_id" {
  description = "Set as GitHub Actions variable AZURE_CLIENT_ID"
  value       = azuread_application.github.client_id
}

output "tenant_id" {
  description = "Set as GitHub Actions variable AZURE_TENANT_ID"
  value       = data.azurerm_subscription.current.tenant_id
}

output "subscription_id" {
  description = "Set as GitHub Actions variable AZURE_SUBSCRIPTION_ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "kubeconfig_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name} --overwrite-existing"
}
