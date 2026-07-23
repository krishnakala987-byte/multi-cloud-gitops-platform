# Roadmap

Shipped as versions, like a real internal platform. v1 is complete before
anything else starts. Each extension lands as its own PR with a README note -
public iteration is itself a resume signal ("actively maintained").

## v1.0 (Week 1) - DONE criteria
- [ ] Both clusters from one Terraform codebase (EKS, AKS)
- [ ] ArgoCD hub + ApplicationSet fleet deploys on cluster registration
- [ ] Keyless OIDC CI to both clouds; Trivy-gated image pipeline
- [ ] Grafana Cloud single pane (per-cloud external labels)
- [ ] Route 53 health-checked failover, drill CSV with measured RTO
- [ ] 3+ entries in docs/INCIDENTS.md

## v1.1 (~2 days) - DNS & TLS automation
- **ExternalDNS** on each cluster: Service/Ingress annotations create the
  per-cloud DNS records automatically (replaces hand-filled tfvars in terraform/dns).
- **cert-manager** + Let's Encrypt: HTTPS on the global endpoint.
- Interview line: "DNS and certificates are provisioned by the platform, not by humans."

## v1.2 (~1-2 days) - Secrets done right
- **External Secrets Operator** on both clusters; Grafana Cloud token moves to
  AWS Secrets Manager / Azure Key Vault, synced by ESO.
- Removes every `kubectl create secret` from the runbooks.

## v1.3 (~1-2 days) - Smarter compute (AWS)
- **Karpenter** replaces the EKS managed-node-group autoscaler: just-in-time,
  spot-first provisioning. Big interview topic; AWS-only is fine - say why.

## v2 candidates (only if between offers)
- **Third cloud (GKE)** - the whole point of the fleet design: one new
  Terraform directory + `argocd cluster add` and every ApplicationSet deploys
  to it automatically. Blocked today only by GCP trial payment verification.
- Loki fleet logging via the same ApplicationSet pattern
- Kyverno / OPA Gatekeeper baseline policies
- Velero backup/restore drill (real DR evidence)

## Explicitly rejected for v1 (know your reasons)
- Service mesh (Istio/Linkerd): DNS failover already proves cross-cloud
  resilience; a mesh adds weeks and little interview differentiation here.
- VPA, Jaeger, OTel, Crossplane: real, but they dilute the week. Depth > breadth.
