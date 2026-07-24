# Incident Log

Every real fault I hit while building this, with the actual root cause and fix.
Nothing here is invented. Most interviewers trust this file more than any
feature list, because it shows how I debug, not just what I can wire together.

Each entry follows the same shape: what I saw, how bad it was, how I caught it,
why it happened, what fixed it, and what stops it from happening again.

---

## 1. AKS refused to create the cluster (unsupported VM size)

- **Date:** 2026-07-22
- **Symptom:** `terraform apply` on the Azure module failed at cluster creation. Azure rejected the default node VM size (`Standard_B2s`) for this subscription and region.
- **Blast radius:** Azure cluster only. No AWS impact. Blocked all of Day 1.
- **Detection:** Terraform apply error, plus `az vm list-skus` showed the allowed sizes for centralindia.
- **Root cause:** The `Standard_B2s` (v1 burstable) family is not offered to this subscription in centralindia. Only the v2 burstable sizes are available here. This is a per-subscription, per-region capacity thing, not something you can see until you try.
- **Fix:** Changed the default in `terraform/azure/variables.tf` from `Standard_B2s` to `Standard_B2s_v2`. Re-applied, cluster came up.
- **Prevention:** Don't assume a VM size exists everywhere. Check `az vm list-skus --location <region> --output table` before picking node sizes, and keep the size in a variable so it is a one-line change per region.

---

## 2. ArgoCD install failed on the CRDs (annotation too large)

- **Date:** 2026-07-22
- **Symptom:** `kubectl apply -f https://.../argo-cd/stable/manifests/install.yaml` failed with `metadata.annotations: Too long: may not be more than 262144 bytes`.
- **Blast radius:** The whole GitOps hub. Without ArgoCD there is no fleet, so this blocked everything downstream.
- **Detection:** kubectl error on the apply itself.
- **Root cause:** A plain `kubectl apply` is a client-side apply. It stores the entire object in a `last-applied-configuration` annotation so it can diff next time. The ArgoCD CRDs are huge, and that annotation blew past the 256KB limit Kubernetes puts on annotations.
- **Fix:** Re-ran with server-side apply: `kubectl apply -n argocd --server-side -f <install.yaml>`. Server-side apply lets the API server track field ownership instead of stuffing the whole object into an annotation, so the size cap never comes into play.
- **Prevention:** Use `--server-side` for any large CRD bundle (ArgoCD, kube-prometheus-stack, etc.). The argocd/README install step now uses it by default.

---

## 3. Azure OIDC login failed in CI (AADSTS700213)

- **Date:** 2026-07-23
- **Symptom:** The `terraform-ci` Azure job failed at `azure/login` with an AADSTS700213 error about no matching federated identity record for the incoming token.
- **Blast radius:** Azure half of the keyless CI. AWS auth worked. No infra was down, but I could not run Terraform against Azure from CI.
- **Detection:** GitHub Actions job log on the Azure login step.
- **Root cause:** GitHub changed the format of the OIDC `sub` (subject) claim to embed numeric account and repo IDs, so it now looks like `repo:owner@<accountID>/repo@<repoID>:ref:...`. The Entra federated credential I had set up still expected the old plain `repo:owner/repo:ref:...` format, so the subject never matched.
- **Fix:** Updated the `subject` on the Entra federated credentials (in `terraform/azure/github-oidc.tf`) to the new ID-embedded format, for both the branch and pull_request cases. Verified against a real run: the Azure CLI OIDC login then succeeded.
- **Prevention:** When federating GitHub OIDC, copy the exact `sub` value from a real token in the Actions log rather than hand-writing the format from memory. It has changed once and can change again.

---

## 4. Trivy blocked the build on Go standard library CVEs

- **Date:** 2026-07-23
- **Symptom:** `app-ci` failed at the Trivy scan with about a dozen HIGH severity CVEs, all inside the Go standard library, not my code and not any third-party dependency.
- **Blast radius:** The whole image pipeline. Trivy is a hard gate, so nothing got pushed to GHCR while this failed.
- **Detection:** The Trivy step in the Actions log, with a CVE table pointing at `stdlib`.
- **Root cause:** The image was built on Go 1.24. Go only backports security fixes to its two most recent major releases. Once 1.24 fell out of that window, its standard library stopped receiving patches, so Trivy correctly flagged known-unfixed CVEs in it.
- **Fix:** Bumped the builder image to `golang:1.26-alpine`, set `go-version: "1.26"` in the workflow, and set the `go` directive in `go.mod` accordingly. Rebuilt, scan came back clean.
- **Prevention:** Treat the Go version like a dependency with an expiry date. Stay on one of the two newest majors. A scheduled scan would have caught this before it blocked a real push.

---

## 5. GHCR rejected the image push (write permission denied)

- **Date:** 2026-07-23
- **Symptom:** `app-ci` build-push failed on the docker push with `denied: permission_denied: write_package`.
- **Blast radius:** Image delivery. The build and scan passed, but nothing could be published, so ArgoCD had no new image to pull.
- **Detection:** Actions log on the push step.
- **Root cause:** The repository's default Actions workflow permissions were set to read-only. That repo-level setting overrides the `permissions: packages: write` I had declared in the workflow, so the token never actually had write scope on the package.
- **Fix:** Repo Settings, Actions, General, Workflow permissions, switched to "Read and write permissions". Re-ran, push succeeded.
- **Prevention:** Set the repo-level workflow permission correctly on day zero. The workflow-level `permissions` block cannot grant more than the repo default allows.

---

## 6. Pods stuck in ImagePullBackOff (package was private)

- **Date:** 2026-07-23
- **Symptom:** After the first successful push, both clusters showed `ImagePullBackOff` with a 403 when pulling `ghcr.io/krishnakala987-byte/cloud-atlas`.
- **Blast radius:** The app itself on both clouds. ArgoCD reported the app as Progressing but pods never came up.
- **Detection:** `kubectl describe pod` showed the 403 on the pull.
- **Root cause:** New GHCR packages are private by default. The clusters were pulling anonymously with no pull secret, so a private package returns 403.
- **Fix:** Made the `cloud-atlas` GHCR package public (package settings, change visibility). Pull worked immediately after.
- **Prevention:** Decide public vs private for the registry up front. If it stays private, wire an image pull secret into the deployment instead. For a portfolio project, public is simplest.

---

## 7. Azure LoadBalancer stuck in pending (public IP quota)

- **Date:** 2026-07-23
- **Symptom:** The Azure `cloud-atlas` Service of type LoadBalancer sat at `EXTERNAL-IP <pending>` and never got an address.
- **Blast radius:** External access to the Azure app. The pods were healthy, just not reachable from outside.
- **Detection:** `kubectl describe svc` showed a `PublicIPCountLimitReached` event from the cloud controller.
- **Root cause:** The Azure free tier caps public IPs at 3 per region. An earlier throwaway test app had been deleted, but its public IP was left behind and was still counting against the quota, so there was no room for the new LB's IP.
- **Fix:** Found the orphaned IP with `az network public-ip list` and deleted it with `az network public-ip delete`. The LoadBalancer picked up an address on the next reconcile.
- **Prevention:** Clean up public IPs when deleting test resources, not just the resource that created them. Watch the per-region quota on free tier.

---

## 8. AWS refused to create any LoadBalancer (account-level restriction)

- **Date:** 2026-07-24
- **Symptom:** The AWS `cloud-atlas` Service stayed at `<pending>`. Events showed `OperationNotPermitted: This AWS account currently does not support creating load balancers.`
- **Blast radius:** External access to the AWS app, and by extension the DNS failover demo, which needs the AWS LB endpoint. Everything internal to the cluster was fine.
- **Detection:** `kubectl describe svc` on the AWS context. I also confirmed it was not IAM by checking that every read and describe call worked and only the create was refused, and not a quota issue since there was no quota-exceeded error.
- **Root cause:** An account-level trust restriction on this account blocked Elastic Load Balancer creation outright. This is separate from IAM permissions and from service quotas. It is a flag on the account that only AWS can lift.
- **Fix:** Opened an AWS Support case under Account and Billing (not the service-limit form, which would have been the wrong queue) with the account ID, region, exact error, and context. Support removed the restriction. I then deleted the stuck Service, ArgoCD self-healed and recreated it, and the NLB provisioned. Confirmed with a curl to the NLB hostname returning healthy and reporting `"cloud":"aws"`.
- **Prevention:** Not really preventable from my side, it is an account state. The lesson is diagnostic: prove it is not IAM and not quota first, then raise it as an account issue in the correct support queue so it does not bounce.

---

## 9. Private Route 53 zone would not associate with the VPC

- **Date:** 2026-07-24
- **Symptom:** `terraform apply` on the DNS module failed creating the hosted zone: `InvalidVPCId: The VPC vpc-07a6a6d... in region us-east-1 that you provided is not authorized to make the association.` The VPC is in ap-south-1, not us-east-1.
- **Blast radius:** The DNS module only. The health checks had already been created; just the zone and records were blocked.
- **Detection:** Terraform apply error, which helpfully named the wrong region.
- **Root cause:** For a private hosted zone, the `vpc` association block defaults the region to us-east-1 when you do not set it explicitly. My VPC lives in ap-south-1, so the association pointed at a region where that VPC does not exist.
- **Fix:** Added `vpc_region = "ap-south-1"` to the `vpc` block in `terraform/dns/main.tf`. Re-applied, the zone and all records created cleanly.
- **Prevention:** Always set `vpc_region` explicitly on private zone associations. Do not rely on the default.

---

## 10. ServiceMonitor not created (feature not enabled in values)

- **Date:** 2026-07-23
- **Symptom:** Prometheus was running on both clusters but was not scraping the app, and `kubectl get servicemonitor -n cloud-atlas` returned nothing.
- **Blast radius:** App metrics only. The clusters and the app were fine, but nothing showed up in Grafana for cloud-atlas.
- **Detection:** No ServiceMonitor object present, and no cloud-atlas target in Prometheus.
- **Root cause:** The chart ships the ServiceMonitor behind a `serviceMonitor.enabled` flag that defaulted to false, so the template never rendered the object.
- **Fix:** Set `serviceMonitor.enabled: true` in the chart values through a Git commit (not a manual kubectl edit, since the whole point is GitOps), let ArgoCD sync, and the ServiceMonitor appeared on both clusters. Metrics started flowing to Grafana Cloud right after.
- **Prevention:** When wiring monitoring, confirm the ServiceMonitor exists as a first check, not the pod. A running Prometheus with no targets is the common failure and it is silent.

---

## Template (for the next one)

- **Date:**
- **Symptom:**
- **Blast radius:**
- **Detection:**
- **Root cause:**
- **Fix:**
- **Prevention:**
