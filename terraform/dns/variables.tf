variable "zone_id" {
  description = "Route 53 hosted zone ID for your domain"
  type        = string
}

variable "app_fqdn" {
  description = "Public name for the app, e.g. app.yourdomain.xyz"
  type        = string
}

variable "aws_nlb_dns_name" {
  description = "EKS Service LB hostname (kubectl --context aws get svc cloud-atlas)"
  type        = string
  default     = ""
}

variable "azure_lb_ip" {
  description = "AKS Service LB external IP"
  type        = string
  default     = ""
}

