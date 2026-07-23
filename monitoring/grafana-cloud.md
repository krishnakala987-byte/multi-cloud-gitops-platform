# Single pane of glass: Grafana Cloud (free tier)

1. Sign up at grafana.com (free tier: 10k metric series - plenty).
2. Grab the Prometheus remote-write details: **Push URL**, **Username/Instance ID**, and create an **API token** with `metrics:write`.
3. Put the push URL into `argocd/monitoring-appset.yaml` (REPLACE_WITH_GRAFANA_CLOUD_PUSH_URL).
4. Create the auth secret on EACH cluster:
   ```bash
   for ctx in aws azure; do
     kubectl --context $ctx create ns monitoring --dry-run=client -o yaml | kubectl --context $ctx apply -f -
     kubectl --context $ctx -n monitoring create secret generic grafana-cloud \
       --from-literal=username=<INSTANCE_ID> --from-literal=password=<API_TOKEN>
   done
   ```
5. `kubectl apply -f argocd/monitoring-appset.yaml` on the hub.
6. In Grafana Cloud -> Explore, prove the story with one query:
   ```promql
   sum by (cloud) (cloud_atlas_requests_total)
   ```
   Two lines: aws and azure. Screenshot it for the README - this is the
   money shot of the whole project.

Build a dashboard with panels split by `cloud` / `cluster` external labels:
request rate per cloud, `cloud_atlas_up` availability map, node CPU/memory
per cluster (from kube-prometheus-stack defaults).
