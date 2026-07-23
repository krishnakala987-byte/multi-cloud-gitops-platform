# AKS with the FREE control-plane tier + 2 burstable B2s nodes.
# Cost profile on the $200/30-day credit: ~ $1.5-2/day while up.

resource "azurerm_resource_group" "this" {
  name     = "${var.cluster_name}-rg"
  location = var.location
  tags = {
    project = "multi-cloud-gitops-platform"
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.cluster_name
  sku_tier            = "Free" # control plane costs nothing

  default_node_pool {
    name       = "system"
    node_count = 2
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project = "multi-cloud-gitops-platform"
  }
}
