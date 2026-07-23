output "app_url" {
  value = "http://${var.app_fqdn}/"
}

output "per_cloud_urls" {
  value = { for k in keys(local.active) : k => "http://${k}.${var.app_fqdn}/" }
}
