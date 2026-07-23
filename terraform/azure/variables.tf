variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "atlas-azure"
}

variable "node_vm_size" {
  description = "VM size for the default node pool (B-series = cheapest burstable)"
  type        = string
  default     = "Standard_B2s"
}

variable "github_repo" {
  description = "GitHub repo allowed to federate (owner/name)"
  type        = string
  default     = "krishnakala987-byte/multi-cloud-gitops-platform"
}
