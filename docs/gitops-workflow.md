# GitOps Workflow — Manifests Repo

This is the **source of truth** for the e-commerce platform running on Kubernetes.  
ArgoCD watches this repository and automatically syncs any changes to the cluster.

## How Changes Flow

```
1. Developer pushes code to ecommerce-app  (github.com/yourorg/ecommerce-app)
2. Jenkins CI builds, tests, scans, pushes Docker images
3. Jenkins updates image tags in THIS repo (ecommerce-manifests)
4. ArgoCD detects the change (drift from Git)
5. ArgoCD auto-syncs to the Kubernetes cluster
6. Kubernetes performs rolling update with new images
```

## What's in This Repo

| Directory | Contents |
|-----------|----------|
| `deploy/k8s/base/` | Raw K8s manifests per service (Deployment, Service, HPA) |
| `deploy/k8s/overlays/` | Kustomize overlays for dev/staging/prod envs |
| `deploy/argocd/` | ArgoCD AppProject + Application definitions |
| `monitoring/` | Prometheus rules, Grafana dashboards, ELK config |
| `security/` | Vault config, Trivy scan configs |
| `backup/` | Backup scripts and DR documentation |
| `infra/` | Terraform modules and Ansible playbooks |

## ArgoCD Applications

| Application | Source Path | Namespace | Sync Policy |
|-------------|-------------|-----------|-------------|
| `ecommerce-infra` | `deploy/k8s/base/infra` | `ecommerce-infra` | Auto-prune, self-heal |
| `ecommerce-services` | `deploy/k8s/overlays/prod` | `ecommerce` | Auto-prune, self-heal |
| `ecommerce-monitoring` | `monitoring/prometheus` | `monitoring` | Auto-prune, self-heal |

All applications are managed via the **App-of-Apps** pattern through `deploy/argocd/applications/root-app.yaml`.

## Manual Workflow

```bash
# Preview what would change
argocd app diff ecommerce-services

# Force sync (if auto-sync is off)
argocd app sync ecommerce-services --prune

# Rollback to previous state
git revert HEAD --no-edit && git push origin main
# ArgoCD auto-syncs the revert
```

## Editing Manifests

1. Checkout and branch
```bash
git checkout -b fix/increase-auth-replicas
```

2. Make changes
```bash
# Edit deployment replicas
vim deploy/k8s/base/auth/deployment.yaml
```

3. Validate
```bash
kustomize build deploy/k8s/overlays/prod | kubectl apply --dry-run=client -f -
```

4. Commit, push, PR
```bash
git add .
git commit -m "fix: increase auth replicas from 2 to 3"
git push origin fix/increase-auth-replicas
# Create PR → merge to main → ArgoCD syncs
```
