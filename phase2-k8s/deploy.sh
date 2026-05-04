#!/bin/bash
# =============================================================================
# PHASE 2 — Kubernetes Deploy Script
# Chạy từ máy local với KUBECONFIG đã setup từ Phase 1
# =============================================================================

set -e
KUBECONFIG_PATH="./kubeconfig"    # Hoặc ~/.kube/config

echo "============================================================"
echo "PHASE 2 — K8s Architecture Deploy"
echo "============================================================"

# STEP 1: Tạo namespace
echo "[1/7] Creating production namespace..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f namespace.yaml

# STEP 2: Deploy secrets TRƯỚC (backend + database cần đọc secrets)
echo "[2/7] Applying Secrets..."
echo "Nhớ sửa giá trị CHANGE_ME trong các file secret trước!"
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f backend/secret.yaml
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f database/statefulset.yaml   # Secret ở trong file này

# STEP 3: Apply ConfigMaps
echo "[3/7] Applying ConfigMaps..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f frontend/configmap.yaml
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f backend/configmap.yaml

# STEP 4: Deploy Database (phải lên trước backend)
echo "[4/7] Deploying PostgreSQL StatefulSet..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f database/statefulset.yaml

echo "Waiting for PostgreSQL to be ready..."
kubectl --kubeconfig=$KUBECONFIG_PATH wait \
  --namespace=production \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=120s

# STEP 5: Deploy Backend
echo "[5/7] Deploying Backend..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f backend/deployment.yaml
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f backend/hpa.yaml

kubectl --kubeconfig=$KUBECONFIG_PATH wait \
  --namespace=production \
  --for=condition=available deployment/backend \
  --timeout=120s

# STEP 6: Deploy Frontend
echo "[6/7] Deploying Frontend..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f frontend/deployment.yaml
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f frontend/hpa.yaml

kubectl --kubeconfig=$KUBECONFIG_PATH wait \
  --namespace=production \
  --for=condition=available deployment/frontend \
  --timeout=120s

# STEP 7: Apply Ingress (TLS sẽ được cert-manager xử lý)
echo "[7/7] Applying Ingress with TLS..."
kubectl --kubeconfig=$KUBECONFIG_PATH apply -f ingress/ingress.yaml

echo ""
echo "============================================================"
echo "DEPLOY COMPLETE! Verifying cluster state..."
echo "============================================================"

kubectl --kubeconfig=$KUBECONFIG_PATH get all --namespace=production
echo ""
kubectl --kubeconfig=$KUBECONFIG_PATH get hpa --namespace=production
echo ""
kubectl --kubeconfig=$KUBECONFIG_PATH get ingress --namespace=production
echo ""
echo "TLS Certificate status (chờ 1-2 phút để cert-manager issue cert):"
kubectl --kubeconfig=$KUBECONFIG_PATH get certificate --namespace=production
