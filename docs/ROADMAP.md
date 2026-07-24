# Roadmap

Shipped as versions, like a real internal platform. v1.0 is complete. Each
extension lands as its own PR with a README note. Iterating in public is itself
a signal that the project is maintained, not abandoned after one commit.

## v1.0 (Week 1), complete

- [x] Both clusters from one Terraform codebase (EKS, AKS)
- [x] ArgoCD hub plus ApplicationSet fleet deploys on cluster registration
- [x] Keyless OIDC CI to both clouds, Trivy-gated image pipeline
- [x] Grafana Cloud single pane with per-cloud external labels
- [x] Route 53 health-checked failover, verified by scaling a cloud to zero and watching DNS drop it
- [x] Custom Grafana dashboard and Prometheus alert rules
- [x] Real incidents documented in docs/INCIDENTS.md (10 entries)

## v1.1 (~2 days): DNS and TLS automation

- **ExternalDNS** on each cluster, so Service and Ingress annotations create the per-cloud DNS records automatically instead of hand-filled tfvars in terraform/dns.
- **cert-manager** with Let's Encrypt for HTTPS on the endpoint. This pairs with moving the private DNS zone to a public one (see below), since TLS only matters once the app is reachable from outside the VPC.
- Interview line: DNS and certificates get provisioned by the platform, not by a human editing tfvars.

## v1.2 (~1 to 2 days): Secrets done right

- **External Secrets Operator** on both clusters. The Grafana Cloud token moves into AWS Secrets Manager and Azure Key Vault, synced in by ESO.
- Removes every `kubectl create secret` from the runbooks.

## v1.3 (~1 to 2 days): Smarter compute on AWS

- **Karpenter** replaces the EKS managed node group autoscaler for just-in-time, spot-first provisioning. It is a common interview topic. AWS-only is fine here, and being able to say why is the point.

## Public DNS (small, do when it makes sense)

- The current failover uses a Route 53 private hosted zone, which only resolves inside the AWS VPC (this was a deliberate cost choice, no domain purchased). Swapping it for a public zone plus a cheap domain makes the same weighted routing and health checks demoable from a browser, and unlocks cert-manager above.

## v2 candidates (only if between offers)

- **Third cloud (GKE).** This is the whole reason the fleet is built the way it is. One new Terraform directory plus `argocd cluster add` and every ApplicationSet deploys to it automatically. Left out of v1 only because the GCP trial wanted a large upfront payment to verify.
- Loki fleet logging through the same ApplicationSet pattern the monitoring stack already uses.
- Kyverno or OPA Gatekeeper baseline policies.
- Velero backup and restore drill for real DR evidence.

## Explicitly left out of v1 (and why)

- **Service mesh (Istio or Linkerd).** DNS failover already proves cross-cloud resilience. A mesh adds real time for little extra signal on this particular project.
- **VPA, Jaeger, OpenTelemetry, Crossplane.** All real and useful, but they would have diluted a one-week build. Depth over breadth was the call.
- **Centralized logging (Loki) in v1.** Metrics already prove the observability story end to end. Logging is a clean v1.x add, not a v1 requirement, and adding it late would have been scope creep on an already-working platform.
