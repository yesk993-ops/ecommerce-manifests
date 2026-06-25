#!/bin/bash
set -euo pipefail

# ======================================================
# ArgoCD Bootstrap Script for E-Commerce Platform
# Run this ONCE on a fresh Kubernetes cluster.
# It installs ArgoCD and bootstraps all applications.
# ======================================================

ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="stable"
MANIFESTS_REPO="https://github.com/yourorg/ecommerce-manifests.git"

echo "=== ArgoCD Bootstrap ==="

echo "1. Creating namespace..."
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "2. Installing ArgoCD..."
kubectl apply -n "${ARGOCD_NAMESPACE}" \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "3. Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    -n "${ARGOCD_NAMESPACE}" deployment/argocd-server

echo "4. Exposing ArgoCD server (NodePort)..."
kubectl patch svc argocd-server -n "${ARGOCD_NAMESPACE}" -p '{"spec":{"type":"NodePort"}}'

echo "5. Getting admin password..."
ADMIN_PASSWORD=$(kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)
echo "   ArgoCD admin password: ${ADMIN_PASSWORD}"

echo "6. Applying AppProject..."
kubectl apply -f deploy/argocd/projects/ecommerce-project.yaml

echo "7. Bootstrapping Root Application (App of Apps)..."
kubectl apply -f deploy/argocd/applications/root-app.yaml

echo "8. Waiting for child applications to sync..."
sleep 10
argocd app list 2>/dev/null || true

echo ""
echo "=== Bootstrap Complete ==="
echo "ArgoCD UI:     https://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')"
echo "Admin User:    admin"
echo "Admin Pass:    ${ADMIN_PASSWORD}"
echo ""
echo "Quick login:"
echo "  argocd login --core"
echo "  argocd app list"
