.PHONY: help up-all down-all kubeconfigs register status drill

help: ## List targets
	@grep -E '^[a-zA-Z_%-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

up-%: ## up-aws / up-azure / up-dns
	./scripts/up.sh $*

down-%: ## down-aws / down-azure / down-dns  (COST CONTROL)
	./scripts/down.sh $*

up-all: ## Bring up the whole fleet (azure -> aws)
	./scripts/up.sh all

down-all: ## Destroy everything billable
	./scripts/down.sh all

kubeconfigs: ## Fetch kubeconfigs, alias contexts to aws/azure
	./scripts/kubeconfigs.sh

register: ## Register fleet clusters with the ArgoCD hub
	./scripts/register-clusters.sh

status: ## Fleet snapshot: nodes + app pods on every cluster
	@for c in aws azure; do \
	  echo "=== $$c ==="; \
	  kubectl --context $$c get nodes -o wide 2>/dev/null | head -4; \
	  kubectl --context $$c -n cloud-atlas get pods,svc 2>/dev/null; \
	done

drill: ## Failover drill: make drill URL=http://app.yourdomain.xyz/
	./scripts/failover-drill.sh $(URL)
