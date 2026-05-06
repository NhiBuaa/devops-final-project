#!/bin/bash

# --- Path Configuration ---
# Get the absolute path of the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Link to the kubeconfig file located in phase1-infrastructure/ansible
KUBECONFIG_PATH="$SCRIPT_DIR/../phase1-infrastructure/ansible/kubeconfig"

NS="production"
APP=$2 

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if kubeconfig file exists
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo -e "${RED}Error: Kubeconfig file not found at: $KUBECONFIG_PATH${NC}"
    echo -e "${YELLOW}Suggestion: Ensure you have successfully fetched the file from the Master Node to the phase1-infrastructure/ansible directory.${NC}"
    exit 1
fi

# Wrapper function for kubectl with specified config and namespace
k() {
    kubectl --kubeconfig="$KUBECONFIG_PATH" -n $NS "$@"
}

usage() {
    echo -e "${YELLOW}Usage: ./rollback.sh [mode] [app_name] [revision_id]${NC}"
    echo "Supported modes:"
    echo "  history  : View deployment history (REVISION, CHANGE-CAUSE)"
    echo "  undo     : Roll back to the immediate previous version"
    echo "  revision : Roll back to a specific version (requires ID)"
    echo "  status   : Check the current image tag running in the pod"
    exit 1
}

# Validate input parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

case "$1" in
    history)
        echo -e "${GREEN}==> Deployment history for $APP: ${NC}"
        k rollout history deployment/$APP
        ;;
    undo)
        echo -e "${YELLOW}==> Performing rollback to the latest stable update for $APP...${NC}"
        k rollout undo deployment/$APP
        ;;
    revision)
        if [ -z "$3" ]; then echo -e "${RED}Error: Missing revision ID!${NC}"; exit 1; fi
        echo -e "${YELLOW}==> Rolling back to revision $3 for $APP...${NC}"
        k rollout undo deployment/$APP --to-revision=$3
        ;;
    status)
        echo -e "${GREEN}==> Currently running image tag for $APP: ${NC}"
        k get pods -l app=$APP -o jsonpath='{.items[0].spec.containers[0].image}'
        echo -e "\n"
        ;;
    *)
        usage
        ;;
esac