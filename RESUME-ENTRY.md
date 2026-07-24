# Resume Entry (paste-ready)

## Where it goes

Make this your number one key project, above KubeIntel. It absorbs the
standalone "Terraform EKS Cluster (IaC)" bullet, so delete that from additional
projects to keep the resume at one page. One entry now covers AWS and Azure,
the two clouds most Indian enterprises and MNCs actually run together.

## Main entry (3 bullets, matches your resume's style)

**Multi-Cloud GitOps Platform: One Control Plane for AWS EKS and Azure AKS** · github.com/krishnakala987-byte/multi-cloud-gitops-platform

*Terraform, AWS EKS, Azure AKS, ArgoCD ApplicationSets, Helm, GitHub Actions (OIDC), Prometheus, Grafana Cloud, Route 53, Trivy, Go*

- Provisioned a two-cloud Kubernetes fleet (EKS and AKS) from one Terraform codebase and drove all deployments through a hub-and-spoke ArgoCD with an ApplicationSet cluster generator, so registering a cluster auto-deploys the full stack. One merge to main rolls out to both clouds with self-healing sync and Git-revert rollback. The fleet is provider-agnostic, so a third cloud is one Terraform directory away.
- Removed stored cloud credentials from the entire CI/CD surface by federating GitHub Actions OIDC to both clouds (an AWS IAM role trust policy and Azure Entra workload identity federation). The pipeline gates each release with go test and a Trivy HIGH/CRITICAL scan on a distroless non-root image before a GitOps write-back pins the new tag.
- Verified survival of a full cloud outage: scaling one cloud to zero, Route 53 weighted routing with `/healthz` health checks pulled it out of rotation and served everything from the surviving cloud in about a minute, observed through per-cluster Prometheus remote-writing cloud-labeled metrics to a single Grafana Cloud dashboard. Spot and burstable nodes plus Makefile teardown kept the AWS bill near $12 for the build week.

## Header and skills line updates

- Headline: `DevOps and Cloud Engineer | Linux, AWS, Azure, Kubernetes, Terraform, CI/CD, GitOps, Observability`
- Technical skills, add: `Azure: AKS, Entra ID (workload identity federation), Resource Groups, Azure Load Balancer, Cost Management`
- Summary, first line: change "production-style AWS" to "production-style AWS and Azure" and mention a multi-cloud ArgoCD fleet.

## Short variant (if space is tight, 2 bullets)

- Built a two-cloud Kubernetes fleet (EKS and AKS) from one Terraform codebase, deployed by a hub ArgoCD ApplicationSet, so one merge rolls out to both clouds. Keyless GitHub Actions OIDC on both providers removed every stored cloud credential.
- Proved cross-cloud resilience in a real failover test: after scaling one cloud to zero, health-checked Route 53 routing recovered traffic in about a minute, observed end to end on one Grafana Cloud dashboard fed by per-cluster Prometheus remote_write.

## LinkedIn post (day 6)

> I gave my platform a new failure mode this week: losing an entire cloud.
>
> Built a multi-cloud GitOps platform. One Terraform codebase provisioning AWS
> EKS and Azure AKS, one ArgoCD hub deploying to both, GitHub Actions with zero
> stored cloud keys (OIDC federation on both providers), and one Grafana
> dashboard watching the whole fleet.
>
> Then I scaled one cloud to zero on purpose. Route 53 health checks moved
> traffic to the surviving cloud in about a minute, no manual action. [demo video]
>
> Repo: github.com/krishnakala987-byte/multi-cloud-gitops-platform
> #DevOps #Kubernetes #MultiCloud #GitOps #Terraform #AWS #Azure

## Interview talking points (know these cold)

1. **Why hub-and-spoke ArgoCD?** Central fleet visibility and policy, spokes need no CI credentials, and adding a cluster equals a deploy. Trade-off: the hub is a single point of failure. Mitigations: the hub is rebuildable from Git in minutes, or you run per-cluster Argo for stricter isolation.
2. **How does keyless auth differ per cloud?** Same GitHub OIDC token, two trust models. AWS uses an IAM trust policy with conditions on the `token.actions.githubusercontent.com` sub claim. Azure uses a federated identity credential on an Entra app registration. No rotation, no leakage, blast radius scoped per repo.
3. **Why DNS failover, not anycast or a global LB?** It is the cheapest mechanism that genuinely survives losing a whole provider, and the TTL plus health-check math gives an honest recovery time of roughly 60 to 120 seconds. Next step would be Azure Front Door or CloudFront for L7 and faster convergence.
4. **Why only two clouds?** AWS plus Azure is the most common enterprise pair, the design is provider-agnostic, and adding GKE is one Terraform directory plus `argocd cluster add`. It is on the roadmap. Knowing why you scoped it is a senior signal.
5. **What was genuinely hard?** Pull specifics from docs/INCIDENTS.md. Good ones: Go standard-library CVEs failing Trivy because Go only patches its two newest majors, an AWS account-level restriction on load balancer creation that needed a support case to lift, GitHub changing its OIDC subject format so Azure federation stopped matching, and a private Route 53 zone defaulting to the wrong region for VPC association.
6. **What would production add?** Remote state with plan and apply pipelines and approvals, External Secrets Operator instead of kubectl-created secrets, per-cloud registries, NetworkPolicies, and SLOs wired to the alert rules.
