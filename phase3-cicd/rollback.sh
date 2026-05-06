#!/bin/bash

# --- Cấu hình ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Liên kết đến file kubeconfig được Ansible fetch về ở Phase 1
KUBECONFIG_PATH="$SCRIPT_DIR/../phase1-infrastructure/ansible/kubeconfig"

NS="production"
APP="backend"

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Kiểm tra file kubeconfig 
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo -e "${RED}Lỗi: Không tìm thấy file kubeconfig tại: $KUBECONFIG_PATH${NC}"
    echo -e "${YELLOW}Gợi ý: Đảm bảo bạn đã chạy Ansible ở Phase 1 để fetch file về máy local.${NC}"
    exit 1
fi

# Hàm k thực thi lệnh qua file config đã liên kết
k() {
    kubectl --kubeconfig="$KUBECONFIG_PATH" -n $NS "$@"
}

usage() {
    echo -e "${YELLOW}Sử dụng: ./rollback.sh [mode] [app] [value]${NC}"
    echo "Các mode hỗ trợ:"
    echo "  history  : Xem lịch sử các bản cập nhật (Mode history)"
    echo "  undo     : Quay lại phiên bản ngay trước đó (Mode undo)"
    echo "  revision : Quay lại một phiên bản cụ thể (Mode revision - cần truyền ID)"
    echo "  status   : Kiểm tra version/tag hiện tại của pod (Mode tag)"
    exit 1
}

case "$1" in
    history)
        echo -e "${GREEN}==> Lịch sử triển khai của $2: ${NC}"
        k rollout history deployment/$2
        ;;
    undo)
        echo -e "${YELLOW}==> Đang thực hiện Rollback bản cập nhật gần nhất cho $2...${NC}"
        k rollout undo deployment/$2
        ;;
    revision)
        if [ -z "$3" ]; then echo "Thiếu ID revision!"; exit 1; fi
        echo -e "${YELLOW}==> Đang quay lại revision $3 cho $2...${NC}"
        k rollout undo deployment/$2 --to-revision=$3
        ;;
    status)
        echo -e "${GREEN}==> Image tag hiện tại đang chạy: ${NC}"
        k get pods -l app=$2 -o jsonpath='{.items[0].spec.containers[0].image}'
        echo -e "\n"
        ;;
    *)
        usage
        ;;
esac