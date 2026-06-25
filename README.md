# E-Commerce Manifests Repository

**GitOps source of truth** for the e-commerce platform's Kubernetes infrastructure.

This repo is consumed by ArgoCD. Never edit deployed resources directly — all changes flow through Git.

## Repositories

| Repo | URL | Purpose |
|------|-----|---------|
| **Manifests (this repo)** | `github.com/yourorg/ecommerce-manifests` | K8s manifests, ArgoCD apps, monitoring, infra |
| **App Code** | `github.com/yourorg/ecommerce-app` | Microservices source code, CI pipeline |

## GitOps Workflow

```
Developer Push → App Repo
    ↓
Jenkins CI Pipeline (build, test, scan, push images)
    ↓
Jenkins updates image tags in THIS repo (commit + push)
    ↓
ArgoCD detects drift → auto-syncs to Kubernetes
    ↓
Kubernetes cluster converges to desired state
```

## Directory Structure

```
├── deploy/
│   ├── k8s/
│   │   ├── base/         # Raw K8s manifests per service
│   │   └── overlays/     # Kustomize overlays (dev/staging/prod)
│   └── argocd/
│       ├── projects/     # ArgoCD AppProject definitions
│       └── applications/ # ArgoCD Application definitions
├── monitoring/           # Prometheus, Grafana, ELK config
├── security/             # Vault, Trivy, SonarQube config
├── backup/               # Backup scripts & DR docs
└── infra/                # Terraform & Ansible (IaC)
```
