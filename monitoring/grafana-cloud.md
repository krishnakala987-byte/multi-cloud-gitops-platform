# Single pane of glass: Grafana Cloud (free tier)

1. Sign up at grafana.com. The free tier gives 10k metric series, which is plenty here.
2. Grab the Prometheus remote-write details: the **Push URL**, the **Username / Instance ID**, and an **API token** with the `metrics:write` scope.
3. Put the push URL into `argocd/monitoring-appset.yaml` (replace `REPLACE_WITH_GRAFANA_CLOUD_PUSH_URL`).
4. Create the auth secret on EACH cluster:
   ```bash
   for ctx in aws azure; do
     kubectl --context $ctx create ns monitoring --dry-run=client -o yaml | kubectl --context $ctx apply -f -
     kubectl --context $ctx -n monitoring create secret generic grafana-cloud \
       --from-literal=username=<INSTANCE_ID> --from-literal=password=<API_TOKEN>
   done
   ```
   The username is the numeric Instance ID from step 2, not your account email.
5. `kubectl apply -f argocd/monitoring-appset.yaml` on the hub.
6. In Grafana Cloud, open Explore and prove the story with one query:
   ```promql
   sum by (cloud) (cloud_atlas_requests_total)
   ```
   You get two lines, aws and azure. Generate a little traffic against each
   cloud so both lines actually move, then screenshot it for the README. This
   is the money shot of the whole project.

## Dashboard and alerts

Rather than hand-building panels, import the dashboard that ships with this repo:

- **Dashboard:** import `monitoring/dashboard.json` (Grafana, Dashboards, New, Import, paste the JSON, then map the Prometheus datasource). Panels: request rate by cloud, total requests, app health (`cloud_atlas_up`), pod CPU and memory, and restarts, all split by cloud.
- **Alerts:** apply `monitoring/alerts.yaml` on each cluster (`kubectl --context <ctx> apply -f monitoring/alerts.yaml`). Rules: app unhealthy, scrape target down, high CPU, and frequent restarts. Confirm the release label matches your kube-prometheus-stack ruleSelector (the file has a note on how to check).
