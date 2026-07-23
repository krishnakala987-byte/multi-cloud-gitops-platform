# Resume Entry (paste-ready)

## Where it goes
Make this your #1 KEY PROJECT, above KubeIntel. It absorbs the standalone
"Terraform EKS Cluster (IaC)" bullet — delete that from ADDITIONAL PROJECTS
to keep the resume at one page. One entry now covers AWS + Azure — the two
clouds most Indian enterprises and MNCs actually run together.

## Main entry (3 bullets, matches your resume's style)

**Multi-Cloud GitOps Platform: One Control Plane for AWS EKS & Azure AKS** · github.com/krishnakala987-byte/multi-cloud-gitops-platform
*Terraform · AWS EKS · Azure AKS · ArgoCD ApplicationSets · Helm · GitHub Actions (OIDC) · Prometheus · Grafana Cloud · Route 53 · Trivy · Go*

- Provisioned a two-cloud Kubernetes fleet (EKS + AKS) from one Terraform codebase and drove all deployments through a hub-and-spoke ArgoCD with an ApplicationSet cluster generator, so registering a cluster auto-deploys the full stack — one merge to main rolls out to both clouds with self-healing sync and Git-revert rollback; the fleet is provider-agnostic, so a third cloud is one Terraform directory away.
- Eliminated stored cloud credentials across the entire CI/CD surface by federating GitHub Actions OIDC to both clouds (AWS IAM role trust policy, Azure Entra workload identity federation); the pipeline gates each release with go test and Trivy HIGH/CRITICAL scans on a distroless non-root image before a GitOps write-back pins the tag.
- Survived the loss of an entire cloud in live failover drills: Route 53 weighted routing with /healthz health checks re-routed global traffic to Azure in under ~2 minutes (measured RTO), with fleet-wide visibility from per-cluster Prometheus remote-writing cloud/cluster-labeled metrics to a single Grafana Cloud dashboard; spot/burstable nodes and Makefile teardown kept the AWS bill ≈ $12 for the build week.

## Header / skills line updates
- Headline: `DevOps & Cloud Engineer | Linux · AWS · Azure · Kubernetes · Terraform · CI/CD · GitOps · Observability`
- TECHNICAL SKILLS — add:
  - `Azure: AKS, Entra ID (workload identity federation), Resource Groups, Azure Load Balancer, Cost Management`
- Summary, first line: "...production-style AWS" → "...production-style **AWS and Azure**" and mention "multi-cloud ArgoCD fleet".

## Short variant (if space is tight, 2 bullets)
- Built a two-cloud Kubernetes fleet (EKS + AKS) from one Terraform codebase, deployed by a hub ArgoCD ApplicationSet — one merge rolls out to both clouds; keyless GitHub Actions OIDC on both providers removed every stored cloud credential.
- Proved cross-cloud resilience in failover drills: health-checked Route 53 routing recovered global traffic in <2 min after killing AWS, observed end-to-end on one Grafana Cloud dashboard fed by per-cluster Prometheus remote_write.

## LinkedIn post (day 6)
> I gave my platform a new failure mode this week: losing an entire cloud.
> Built a multi-cloud GitOps platform — one Terraform codebase provisioning
> AWS EKS and Azure AKS, one ArgoCD hub deploying to both, GitHub Actions
> with zero stored cloud keys (OIDC federation on both providers), and one
> Grafana dashboard watching the whole fleet.
> Then I killed AWS on purpose. Route 53 health checks moved traffic to
> Azure in ~90 seconds. [demo video]
> Repo: github.com/krishnakala987-byte/multi-cloud-gitops-platform
> #DevOps #Kubernetes #MultiCloud #GitOps #Terraform #AWS #Azure

## Interview talking points (know these cold)
1. **Why hub-and-spoke ArgoCD?** Central fleet visibility/policy; spokes need no CI credentials; cluster add = deploy. Trade-off: hub is a SPOF → mitigations: hub is rebuildable from Git in minutes, or per-cluster Argo for stricter isolation.
2. **How does keyless auth differ per cloud?** Same GitHub OIDC token, two trust models: AWS IAM trust policy conditions on the `token.actions.githubusercontent.com` sub claim; Azure federated identity credential on an Entra app registration. No rotation, no leakage, per-repo blast radius.
3. **Why DNS failover, not anycast/global LB?** Cheapest mechanism that truly survives provider loss; TTL + health-check math gives an honest RTO (~60–120s). Next step: Azure Front Door / CloudFront for L7 + faster convergence.
4. **Why only two clouds?** AWS+Azure is the most common enterprise pair; the design is provider-agnostic and adding GKE is one Terraform directory + `argocd cluster add` (it's on the roadmap). Knowing WHY you scoped is a senior signal.
5. **What was genuinely hard?** (Use your INCIDENTS.md — e.g., ApplicationSet template quoting, AKS context names, spot evictions during a drill, ArgoCD selfHeal fighting the chaos drill.)
6. **What would production add?** Remote state + plan/apply pipelines with approvals, ESO instead of kubectl-created secrets, per-cloud registries, NetworkPolicies, SLOs + alert rules.
