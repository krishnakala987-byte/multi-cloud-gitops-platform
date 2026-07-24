# Runbook: Cross-Cloud Failover

## Scenario

One cloud's cluster (or its load balancer) becomes unhealthy. Traffic should
keep getting served from the surviving cloud with no manual action.

## How the recovery works

- Route 53 weighted records for aws and azure, each guarded by an HTTP health check on `/healthz`, with `failure_threshold=2`, `interval=30s`, and a 30s record TTL.
- Expected recovery time (RTO) is roughly 60 to 120 seconds: about 60s for two failed checks, plus the 30s TTL, plus resolver caching.
- RPO is 0. The service is stateless. Real state would live in per-cloud managed databases, out of scope here.

Note on the current setup: the hosted zone is private and associated with the
AWS VPC, so `app.atlas.internal` only resolves from inside that VPC. The drill
below is therefore run from a pod inside the AWS cluster, not from a laptop or
browser. That was a deliberate choice to avoid paying for a public domain. The
mechanism is identical to a public setup; only the vantage point differs.

## Detection

- Repeated DNS lookups from inside the cluster stop returning the failed cloud.
- Grafana Cloud: `cloud_atlas_up == 0` for the failed `cloud` label, or the CloudAtlasTargetDown alert fires.
- Route 53 console: the failed cloud's health check shows Unhealthy.

## Drill procedure (hard failure, the one actually run)

1. Confirm both clouds are in rotation. From a throwaway pod inside the AWS cluster:
   ```bash
   for i in 1 2 3 4 5 6; do
     kubectl --context aws -n cloud-atlas run dns-test-$i \
       --image=busybox:1.36 --restart=Never --rm -it -- \
       nslookup app.atlas.internal | grep "canonical name"
   done
   ```
   Expect a mix of `aws.app.atlas.internal` and `azure.app.atlas.internal`.

2. Kill one cloud. Scale the Azure deployment to zero:
   ```bash
   kubectl --context azure scale deploy/cloud-atlas -n cloud-atlas --replicas=0
   ```

3. Wait about 60 to 90 seconds for the health check to fail, then repeat the
   lookup loop from step 1. Every result should now resolve only to
   `aws.app.atlas.internal`. Azure is gone from the answers.

4. Restore Azure:
   ```bash
   kubectl --context azure scale deploy/cloud-atlas -n cloud-atlas --replicas=2
   ```
   Within a couple of DNS cycles the weighted split returns.

## Drill procedure (soft failure, using the chaos endpoint)

The app exposes chaos toggles, so you can fail a cloud without scaling it down:
```bash
# from inside the cluster, hit the per-cloud service
curl -X POST http://cloud-atlas.cloud-atlas.svc.cluster.local/chaos/unhealthy
# ...run the lookup loop, observe that cloud drop out...
curl -X POST http://cloud-atlas.cloud-atlas.svc.cluster.local/chaos/healthy
```
This flips `cloud_atlas_up` to 0 without touching replicas, which also
exercises the CloudAtlasAppUnhealthy alert.

## A note on ArgoCD self-heal

`selfHeal: true` is on, so if you delete or scale the deployment directly,
ArgoCD will put it back. That is correct behavior and worth demonstrating on
purpose. To hold a cloud down for a longer drill, pause auto-sync first:
```bash
argocd app set cloud-atlas-azure --sync-policy none
# ...run the drill...
argocd app set cloud-atlas-azure --sync-policy automated
```

## Measured result

| Run | Failure type | What happened | Approx RTO |
|---|---|---|---|
| 1 | Azure `replicas=0` | Lookups went from a mix of both clouds to aws-only after the health check failed; Azure fully removed from DNS answers | about 1 minute |

After restoring Azure to two replicas, the weighted split resumed on the next
DNS cycles. Recovery needed no manual DNS change; Route 53 handled it from the
health check alone.

## Post-incident checklist

- Re-enable auto-sync if it was paused: `argocd app set cloud-atlas-<cloud> --sync-policy automated`.
- Confirm both health checks are green and both clouds are back in rotation.
- Add an entry to docs/INCIDENTS.md if the failure was real rather than a drill.
