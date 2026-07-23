variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "atlas-aws"
}

variable "kubernetes_version" {
  description = "EKS version (check latest supported before apply)"
  type        = string
  default     = "1.31"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the CI role via OIDC (owner/name)"
  type        = string
  default     = "krishnakala987-byte/multi-cloud-gitops-platform"
}
