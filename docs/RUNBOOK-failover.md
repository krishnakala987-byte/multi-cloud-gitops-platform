# Runbook: Cross-Cloud Region Failure

## Scenario
One cloud's cluster (or its LB) becomes unhealthy. Global users must keep
getting responses from the surviving clouds with no manual action.

## Architecture behind the recovery
- Route 53 weighted records (aws/azure), each guarded by an HTTP
  health check on `/healthz`, `failure_threshold=2`, `interval=30s`, TTL 30s.
- Expected automatic recovery time (RTO): ~60–120s
  (2 failed checks ≈ 60s + DNS TTL 30s + resolver caching).
- RPO: 0 (stateless service; state would live in per-cloud managed DBs).

## Detection
- `make drill URL=...` shows `UNREACHABLE` or a missing cloud in rotation.
- Grafana Cloud: `cloud_atlas_up == 0` for the failed `cloud` label.
- Route 53 console: health check → Unhealthy.

## Drill procedure (soft failure)
1. Start the observer: `make drill URL=http://app.<domain>/`
2. Inject: `curl -X POST http://aws.app.<domain>/chaos/unhealthy`
3. Record: last AWS-served response timestamp → first window with only azure.
4. Restore: `curl -X POST http://aws.app.<domain>/chaos/healthy`; record time back in rotation.

## Drill procedure (hard failure)
Same, but inject with:
`kubectl --context aws -n cloud-atlas scale deploy/cloud-atlas --replicas=0`
(ArgoCD selfHeal will fight you and restore it — demonstrate that too, then
pause auto-sync for the drill: `argocd app set cloud-atlas-aws --sync-policy none`.)

## Measured results (fill in from failover-drill.csv)
| Run | Failure type | Injected (UTC) | Last bad-cloud hit | Fully failed over | RTO |
|---|---|---|---|---|---|
| 1 | chaos endpoint | | | | |
| 2 | replicas=0 | | | | |

## Post-incident
- Re-enable auto-sync: `argocd app set cloud-atlas-aws --sync-policy automated`
- Verify both health checks green; verify rotation includes both clouds.
- Write 5 lines in docs/INCIDENTS.md: symptom, blast radius, detection time, fix, prevention.
