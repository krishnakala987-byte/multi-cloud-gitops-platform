# ACTIVE-ACTIVE global DNS across both clouds:
# equal-weighted records, each guarded by an HTTP /healthz health check.
# Kill either cloud -> Route 53 stops resolving to it within ~30-60s. That IS
# the failover demo. Cost: ~$0.75/health check/month + $0.50 hosted zone.

locals {
  endpoints = {
    aws   = { enabled = var.aws_nlb_dns_name != "", target = var.aws_nlb_dns_name, is_ip = false }
    azure = { enabled = var.azure_lb_ip != "", target = var.azure_lb_ip, is_ip = true }
  }
  active = { for k, v in local.endpoints : k => v if v.enabled }
}

resource "aws_route53_health_check" "cloud" {
  for_each = local.active

  fqdn              = each.value.is_ip ? null : each.value.target
  ip_address        = each.value.is_ip ? each.value.target : null
  port              = 80
  type              = "HTTP"
  resource_path     = "/healthz"
  request_interval  = 30
  failure_threshold = 2

  tags = { Name = "cloud-atlas-${each.key}" }
}

# AWS NLB hostname must be CNAME-style; the Azure LB is a raw IP (A record).
# Weighted sets require one record type per name, so we publish per-cloud
# names (aws.app.x, azure.app.x) as A/CNAME and weight the main
# name via CNAMEs to those. Simple, standards-compliant, easy to demo.

resource "aws_route53_record" "per_cloud" {
  for_each = local.active

  zone_id = var.zone_id
  name    = "${each.key}.${var.app_fqdn}"
  type    = each.value.is_ip ? "A" : "CNAME"
  ttl     = 30
  records = [each.value.target]
}

resource "aws_route53_record" "weighted" {
  for_each = local.active

  zone_id        = var.zone_id
  name           = var.app_fqdn
  type           = "CNAME"
  ttl            = 30
  set_identifier = each.key
  records        = ["${each.key}.${var.app_fqdn}"]

  weighted_routing_policy {
    weight = 100
  }

  health_check_id = aws_route53_health_check.cloud[each.key].id
}
