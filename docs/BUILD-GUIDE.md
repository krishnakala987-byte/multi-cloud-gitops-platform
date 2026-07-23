# 6-Day Build Guide — Multi-Cloud GitOps Platform (AWS + Azure)

You already run EKS + Terraform + ArgoCD daily. This week you extend that
exact toolchain to AKS. Nothing here is a new *concept* — only a new
*provider*. That's why under a week is enough.

**Golden rules**
1. `make down-aws` at the END of every session. Clusters are cattle; `make up-aws` rebuilds in ~15 min.
2. After Day 2, everything goes through Git + ArgoCD. No hand `kubectl apply` of app manifests — that's the discipline interviewers probe for.
3. Screenshot every milestone (Argo UI with both clusters, Grafana 2-cloud graph, failover CSV). They go in the README and in interviews.

---

## Day 0 (evening, ~1h): Accounts & credits

| Cloud | Offer | Notes |
|---|---|---|
| Azure | **$200 credit / 30 days** + AKS control plane free | Card needed for identity; won't auto-charge — services stop when credit ends unless you upgrade |
| AWS | Your paid account | Spot nodes + single NAT + strict teardown ≈ ~$4/day only while up |

- Create Azure account → note **Subscription ID**.
- Install CLIs: `az` plus your existing `aws`, `kubectl`, `helm`, `terraform`, `argocd`. `az login`.
- **Set billing alerts in both consoles right now** (docs/COST-CONTROL.md).
- Create GitHub repo `multi-cloud-gitops-platform`, push this starter code.
- Optional but recommended (~$2–5): buy a cheap domain (.xyz) for the live failover demo; create a Route 53 hosted zone.

## Day 1 (~2–3h): AKS hub up

1. `make up-azure` → your first AKS cluster. Read `terraform/azure/main.tf` and map each block to its EKS equivalent (cluster resource ↔ EKS module, managed identity ↔ IRSA, sku_tier Free ↔ EKS's $0.10/h fee — a great interview comparison).
2. `make kubeconfigs` → `kubectl --context azure get nodes`.
3. Install ArgoCD on AKS (argocd/README.md §1). AKS hosts the hub because the credit makes it free to keep alive.

**Learned today:** AKS provisioning, Azure resource groups + managed identity, az CLI flow.

## Day 2 (~2–3h): EKS joins — fleet GitOps live

1. Enable your S3 remote-state backend in `terraform/aws/versions.tf` (uncomment, fill bucket/table).
2. `make up-aws` → `make kubeconfigs`.
3. `make register` → both clusters registered with labels.
4. `kubectl --context azure apply -f argocd/cloud-atlas-appset.yaml` → the ApplicationSet stamps out one Application per cluster; both go green. Hit each LB: JSON says `"cloud":"aws"` / `"cloud":"azure"`.
5. Screenshot the Argo UI. End of session: `make down-aws` (hub stays up on credit; the appset re-deploys AWS automatically whenever it re-registers).

**Learned today:** ArgoCD multi-cluster secrets, ApplicationSet cluster generator (the fleet pattern real platform teams use), deploy-by-registration.

> **Start applying TODAY.** Two clouds + fleet GitOps working is already more
> than most applicants show. Push everything, README shows "v1.0 in progress"
> with the roadmap, update your resume honestly, send applications tonight.
> Days 3–6 land while recruiters respond — each is a fresh LinkedIn post.

## Day 3 (~2–3h): Keyless CI/CD across both clouds

1. Collect Terraform outputs:
   - `terraform -chdir=terraform/aws output gha_role_arn`
   - `terraform -chdir=terraform/azure output` (client/tenant/subscription IDs)
2. GitHub → Settings → Variables → add `AWS_GHA_ROLE_ARN`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`. **Zero secrets stored.**
3. PR touching `terraform/` → watch `terraform-ci` authenticate to BOTH clouds via OIDC only.
4. App change → merge → `app-ci` tests, builds, Trivy-scans, pushes to GHCR, commits the new tag into the chart → ArgoCD rolls it out to both clouds. One merge, two clouds — that sentence goes on your resume.
5. Make the GHCR package public (repo → Packages → settings).

**Learned today:** OIDC federation on Azure (Entra federated credentials) vs AWS (IAM trust policy) — the #1 security differentiator interviewers ask about; GitOps write-back.

## Day 4 (~2–3h): One pane of glass

1. Follow `monitoring/grafana-cloud.md`: free Grafana Cloud account, remote-write URL + token, `grafana-cloud` secret on each cluster.
2. Apply `argocd/monitoring-appset.yaml` from the hub.
3. Set `serviceMonitor.enabled: true` via a Git commit (GitOps, not kubectl!).
4. Grafana Cloud: `sum by (cloud) (cloud_atlas_requests_total)` → two lines, two clouds, one dashboard. Screenshot; export dashboard JSON to `monitoring/dashboard.json`.

**Learned today:** federated observability with external labels + remote_write — how enterprises monitor hybrid/multi-cloud.

## Day 5 (~2–3h): Global DNS + the failover demo

1. Both clusters up, LB endpoints from `make status`.
2. `cd terraform/dns && cp terraform.auto.tfvars.example terraform.auto.tfvars` → fill → `make up-dns`.
3. `make drill URL=http://app.yourdomain.xyz/` — responses alternate between clouds (weighted active-active).
4. Break AWS: `curl -X POST http://aws.app.yourdomain.xyz/chaos/unhealthy` → Route 53 pulls AWS out in ~60–90s; the CSV proves your RTO. Restore with `/chaos/healthy`.
5. Harsher: scale the AWS deployment to 0 (ArgoCD selfHeal will fight you — demonstrate that, then pause auto-sync for the drill). Save `failover-drill.csv` + screenshot.
6. Fill the numbers into `docs/RUNBOOK-failover.md`.

**Learned today:** DNS-based global load balancing, health-checked failover, measuring RTO — a real SRE drill on your own platform.

## Day 6 (~2h): Ship it

1. README: paste screenshots, verify every command from a clean clone.
2. Record a 2–3 min demo video: merge → both clouds roll out → kill AWS → traffic survives on Azure. Link it in the README. Recruiters watch videos; they don't read Terraform.
3. Update resume with `RESUME-ENTRY.md`, update LinkedIn.
4. `make down-all`. Post on LinkedIn and keep applying.

---

## If something breaks (it will — that's the point)
Debug it the way you already do on AWS: `kubectl describe`, events, Argo app
conditions, cloud LB consoles. Every fault you fix is an interview story.
Keep `docs/INCIDENTS.md` updated: symptom → root cause → fix. Three entries
there are worth more than any badge.
