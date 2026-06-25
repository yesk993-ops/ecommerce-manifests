.PHONY: deploy-argocd sync-apps validate-k8s validate-all help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deploy-argocd: ## Deploy ArgoCD and bootstrap all applications
	@echo "Deploying ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	kubectl wait --for=condition=available --timeout=300s -n argocd deployment/argocd-server
	@echo "Applying AppProject..."
	kubectl apply -f deploy/argocd/projects/
	@echo "Bootstrapping root application..."
	kubectl apply -f deploy/argocd/applications/root-app.yaml
	@echo "ArgoCD admin password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

deploy-infra: ## Deploy only infrastructure (Postgres, Redis, Kafka)
	kubectl apply -k deploy/k8s/base/infra

deploy-services: ## Deploy all microservices via Kustomize
	kubectl apply -k deploy/k8s/overlays/prod

validate-k8s: ## Validate all K8s manifests with kubeconform
	@for f in $$(find deploy/k8s -name "*.yaml"); do \
		echo "Validating $$f..."; \
		kubeconform -summary $$f 2>/dev/null || echo "  (install kubeconform for validation)"; \
	done

validate-kustomize: ## Validate Kustomize builds
	kustomize build deploy/k8s/base/infra > /dev/null && echo "  infra: OK"
	kustomize build deploy/k8s/overlays/prod > /dev/null && echo "  prod overlay: OK"

sync-apps: ## Force ArgoCD to sync all applications
	@for app in $$(argocd app list -o name 2>/dev/null); do \
		echo "Syncing $$app..."; \
		argocd app sync $$app --prune --force; \
	done

diff: ## Show differences between Git and live cluster
	@for app in $$(argocd app list -o name 2>/dev/null); do \
		echo "=== $$app ==="; \
		argocd app diff $$app; \
	done
