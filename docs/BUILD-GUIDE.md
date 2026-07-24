# 6-Day Build Guide: Multi-Cloud GitOps Platform (AWS + Azure)

If you already run EKS, Terraform, and ArgoCD, this week extends that same
toolchain to AKS. Nothing here is a new concept, only a new provider. That is
why under a week is enough.

**Golden rules**

1. Run `make down-aws` at the END of every session. Clusters are cattle. `make up-aws` rebuilds in about 15 minutes.
2. After Day 2, everything goes through Git and ArgoCD. No hand-running `kubectl apply` on app manifests. That discipline is exactly what interviewers probe for.
3. Screenshot every milestone: the Argo UI with both clusters, the Grafana graph with both clouds, the failover DNS output. They go in the README and into interviews.

---

## Day 0 (evening, ~1h): accounts and credits

| Cloud | Offer | Notes |
|---|---|---|
| Azure | $200 credit for 30 days, plus a free AKS control plane | A card is needed for identity. It will not auto-charge; services stop when the credit ends unless you upgrade. |
| AWS | Your paid account | Spot nodes, a single NAT, and strict teardown keep it to roughly $4/day while up. |

- Create the Azure account and note the Subscription ID.
- Install the CLIs: `az`, plus your existing `aws`, `kubectl`, `helm`, `terraform`, `argocd`. Run `az login`.
- Set billing alerts in both consoles right now (see docs/COST-CONTROL.md).
- Create the GitHub repo `multi-cloud-gitops-platform` and push this starter code.

No domain purchase needed. The failover demo uses a Route 53 private hosted
zone, which is free and does not require owning a domain. See Day 5.

## Day 1 (~2 to 3h): AKS hub up

1. Run `make up-azure` for your first AKS cluster. Read `terraform/azure/main.tf` and map each block to its EKS equivalent: the cluster resource lines up with the EKS module, managed identity with IRSA, and the Free `sku_tier` with the $0.10/h EKS control-plane fee. That comparison is a good interview answer on its own.
2. Run `make kubeconfigs`, then `kubectl --context azure get nodes`.
3. Install ArgoCD on AKS (argocd/README.md, step 1). AKS hosts the hub because the credit makes it free to keep running.

One thing you will hit here: the default node VM size may not be offered in
your region for your subscription. If apply fails on the SKU, check
`az vm list-skus` and pick an available one. This project uses `Standard_B2s_v2`
in centralindia for that reason (documented as incident 1).

**Learned today:** AKS provisioning, Azure resource groups and managed identity, the az CLI flow.

## Day 2 (~2 to 3h): EKS joins the fleet

1. Optionally enable your S3 remote-state backend in `terraform/aws/versions.tf` (uncomment, fill in bucket and table).
2. Run `make up-aws`, then `make kubeconfigs`.
3. Run `make register` so both clusters are registered with fleet labels.
4. Apply the app ApplicationSet from the hub: `kubectl --context azure apply -f argocd/cloud-atlas-appset.yaml`. It stamps out one Application per cluster and both go green. Hit each load balancer and the JSON reports `"cloud":"aws"` or `"cloud":"azure"`.
5. Screenshot the Argo UI. End the session with `make down-aws`. The hub stays up on credit and re-deploys AWS automatically whenever it re-registers.

**Learned today:** ArgoCD multi-cluster secrets, the ApplicationSet cluster generator (the fleet pattern real platform teams use), deploy-by-registration.

> **Start applying early.** Two clouds plus fleet GitOps working is already more
> than most applicants show. Once Day 2 is solid you can push everything, update
> your resume honestly, and send applications while Days 3 to 6 land. Each later
> day is a fresh LinkedIn post.

## Day 3 (~2 to 3h): keyless CI/CD across both clouds

1. Collect the Terraform outputs:
   - `terraform -chdir=terraform/aws output gha_role_arn`
   - `terraform -chdir=terraform/azure output` (client, tenant, subscription IDs)
2. In GitHub, Settings, Variables, add `AWS_GHA_ROLE_ARN`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`. Zero secrets stored, only non-sensitive IDs.
3. Open a PR touching `terraform/` and watch `terraform-ci` authenticate to both clouds through OIDC alone.
4. Make an app change, merge, and `app-ci` tests, builds, Trivy-scans, pushes to GHCR, and commits the new tag into the chart. ArgoCD then rolls it out to both clouds. One merge, two clouds.
5. Make the GHCR package public (the repo Packages settings). New packages are private by default, which otherwise causes ImagePullBackOff.

Two gotchas live here, both documented in INCIDENTS.md: the repo's default
Actions workflow permission has to be set to read and write or the push is
denied, and the Azure OIDC subject must use GitHub's current ID-embedded format.

**Learned today:** OIDC federation on Azure (Entra federated credentials) versus AWS (IAM trust policy), which is the security difference interviewers ask about most, plus the GitOps write-back pattern.

## Day 4 (~2 to 3h): one pane of glass

1. Follow `monitoring/grafana-cloud.md`: a free Grafana Cloud account, the remote-write URL and token, and a `grafana-cloud` secret on each cluster.
2. Apply `argocd/monitoring-appset.yaml` from the hub.
3. Set `serviceMonitor.enabled: true` through a Git commit (GitOps, not a manual kubectl edit). Without this the ServiceMonitor never renders and Prometheus scrapes nothing.
4. In Grafana Cloud, run `sum by (cloud) (cloud_atlas_requests_total)` and you get one line per cloud on one dashboard. Generate a little traffic against each cloud so both lines actually move, then screenshot.
5. Import `monitoring/dashboard.json` (request rate, total requests, health, CPU, memory, restarts, split by cloud) and apply `monitoring/alerts.yaml` (app unhealthy, target down, high CPU, frequent restarts) on both clusters.

**Learned today:** federated observability with external labels and remote_write, which is how real teams monitor across clouds, plus building a dashboard and alert rules on top.

## Day 5 (~2 to 3h): global DNS and the failover demo

1. Both clusters up, load balancer endpoints from `make status`.
2. Collect the four values the DNS module needs: the AWS VPC ID (`terraform -chdir=terraform/aws output vpc_id`), the AWS NLB hostname, the Azure LB IP, and an internal app name like `app.atlas.internal`.
3. In `terraform/dns`, copy `terraform.auto.tfvars.example` to `terraform.auto.tfvars`, fill in those values, then `make up-dns`. This creates a private hosted zone associated with the AWS VPC, weighted records for both clouds, and a health check per cloud on `/healthz`.
4. Verify normal operation from inside the AWS cluster with a throwaway busybox pod running `nslookup app.atlas.internal`. Repeated lookups return a mix of both clouds.
5. Do the failover: scale Azure to zero (`kubectl --context azure scale deploy/cloud-atlas -n cloud-atlas --replicas=0`), wait about a minute for the health check to fail, and repeat the lookups. Every answer now resolves to AWS only. Scale Azure back to two and the split returns. Record this; it is your best demo clip.
6. Fill the result into docs/RUNBOOK-failover.md.

One real snag to expect: a private zone association defaults to us-east-1, so
set `vpc_region` explicitly to your VPC's region (incident 9).

**Learned today:** DNS-based failover, health-checked routing, and measuring recovery time, which is a real SRE drill on your own platform.

## Day 6 (~2h): ship it

1. README: paste in the screenshots and verify every command from a clean clone.
2. Record a 2 to 3 minute demo video: merge, both clouds roll out, kill one cloud, traffic survives on the other. Link it in the README. Recruiters watch a short video; they do not read Terraform.
3. Update the resume from RESUME-ENTRY.md and update LinkedIn.
4. Run `make down-all`, then keep applying.

---

## When something breaks (it will, that is the point)

Debug it the way you already do on AWS: `kubectl describe`, events, ArgoCD app
conditions, the cloud LB consoles. Every fault you fix is an interview story.
Keep docs/INCIDENTS.md current: symptom, root cause, fix. A handful of real
entries there are worth more than any badge.
