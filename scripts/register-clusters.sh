#!/usr/bin/env bash
# Register both clusters with the ArgoCD hub, labeled for the ApplicationSets.
# Prereq: argocd CLI logged in to the hub (see argocd/README.md).
set -euo pipefail

argocd cluster add azure --name azure --label fleet=atlas --label cloud=azure --label region=centralindia --yes
argocd cluster add aws   --name aws   --label fleet=atlas --label cloud=aws   --label region=ap-south-1   --yes

argocd cluster list
