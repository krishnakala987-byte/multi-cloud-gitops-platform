# ArgoCD hub-and-spoke setup

The hub runs on AKS (free control plane, nodes paid by the $200 for 30 days
credit, so it stays up all build week for free). EKS is the spoke, registered
as an ArgoCD cluster secret and torn down daily to save money. It re-joins the
fleet in minutes when recreated.

## 1. Install ArgoCD on the hub (AKS context)

```bash
kubectl config use-context azure
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
# initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
argocd login localhost:8080 --username admin --insecure
```

Note the `--server-side` flag on the install. The ArgoCD CRDs are too large for
a client-side apply, which would fail on the 256KB annotation limit (see
docs/INCIDENTS.md, incident 2).

## 2. Register the fleet (labels drive the ApplicationSets)

```bash
./scripts/register-clusters.sh
# or manually:
argocd cluster add azure --name azure --label fleet=atlas --label cloud=azure --label region=centralindia --yes
argocd cluster add aws   --name aws   --label fleet=atlas --label cloud=aws   --label region=ap-south-1  --yes
```

## 3. Deploy the fleet apps

```bash
kubectl apply -f argocd/cloud-atlas-appset.yaml
kubectl apply -f argocd/monitoring-appset.yaml   # after creating the grafana-cloud secrets
argocd app list   # watch both apps go Healthy and Synced
```