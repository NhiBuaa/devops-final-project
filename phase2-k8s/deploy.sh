#!/bin/bash
set -e

# --- Cấu hình ---
# Sử dụng đường dẫn linh hoạt hoặc tuyệt đối
KUBECONFIG_PATH="../phase1-infrastructure/ansible/kubeconfig"
NS="production"

# Màu sắc cho terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}============================================================${NC}"
echo -e "${YELLOW}STARTING DEPLOYMENT PHASE 2 — K8S ARCHITECTURE${NC}"
echo -e "${YELLOW}============================================================${NC}"

# Kiểm tra file kubeconfig
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo -e "Error: Kubeconfig file not found at $KUBECONFIG_PATH"
    exit 1
fi

k() {
  kubectl --kubeconfig="$KUBECONFIG_PATH" "$@"
}

# STEP 1: Namespace
echo -e "${GREEN}[1/7] Creating namespace...${NC}"
k apply -f namespace.yaml

# STEP 2: Secrets & ConfigMaps
echo -e "${GREEN}[2/7] Applying Secrets and ConfigMaps...${NC}"
# Chỉ apply những gì cần thiết, tránh lặp lại file database
k apply -f backend/secret.yaml -n $NS
k apply -f backend/configmap.yaml -n $NS
k apply -f frontend/configmap.yaml -n $NS

# STEP 3: Database (StatefulSet)
echo -e "${GREEN}[3/7] Deploying PostgreSQL StatefulSet...${NC}"
k apply -f database/statefulset.yaml -n $NS

echo "Waiting for PostgreSQL pod to be ready..."
# Đợi chính xác pod postgres-0 (đặc trưng của StatefulSet)
k wait --namespace=$NS --for=condition=ready pod/postgres-db-0 --timeout=120s

# STEP 4: Backend
echo -e "${GREEN}[4/7] Deploying Backend & HPA...${NC}"
k apply -f backend/deployment.yaml -n $NS
k apply -f backend/hpa.yaml -n $NS

echo "Waiting for Backend deployment to be available..."
k rollout status deployment/backend -n $NS --timeout=120s

# STEP 5: Frontend
echo -e "${GREEN}[5/7] Deploying Frontend & HPA...${NC}"
k apply -f frontend/deployment.yaml -n $NS
k apply -f frontend/hpa.yaml -n $NS

echo "Waiting for Frontend deployment to be available..."
k rollout status deployment/frontend-deployment -n $NS --timeout=120s

# STEP 6: Ingress
echo -e "${GREEN}[6/7] Applying Ingress (TLS)...${NC}"
k apply -f ingress/ingress.yaml

echo -e "${YELLOW}============================================================${NC}"
echo -e "${YELLOW}DEPLOY COMPLETE! VERIFYING...${NC}"
echo -e "${YELLOW}============================================================${NC}"

k get pods,svc,hpa,ingress -n $NS
echo -e "\n${GREEN}Wait 1-2 minutes for the cert-manager to issue the SSL Certificate...${NC}"
k get certificate -n $NS
