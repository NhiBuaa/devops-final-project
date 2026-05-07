#!/bin/bash
# =============================================================================
# ROLLBACK STRATEGY — Manual & Automated
# Dùng khi cần rollback khẩn cấp ngoài pipeline
# =============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
NAMESPACE="${1:-production}"   # Default: production
KUBECONFIG_PATH="$SCRIPT_DIR/../phase1-infrastructure/ansible/kubeconfig"

k() {
    kubectl --kubeconfig="$KUBECONFIG_PATH" -n "$NAMESPACE" "$@"
}

echo "============================================================"
echo "ROLLBACK STRATEGY GUIDE — Namespace: $NAMESPACE"
echo "============================================================"

# ─── XEM LỊCH SỬ REVISION ────────────────────────────────────────────────
show_history() {
    echo ""
    echo "[1] Rollout History — Frontend"
    k rollout history deployment/frontend -n "$NAMESPACE"

    echo ""
    echo "[1] Rollout History — Backend"
    k rollout history deployment/backend -n "$NAMESPACE"
}

# ─── ROLLBACK VỀ REVISION TRƯỚC ─────────────────────────────
rollback_one_step() {
    echo ""
    echo "[2] Rolling back both deployments by ONE revision..."

    k rollout undo deployment/frontend -n "$NAMESPACE"
    k rollout undo deployment/backend -n "$NAMESPACE"

    echo "Waiting for rollback to complete..."
    k rollout status deployment/frontend -n "$NAMESPACE" --timeout=180s
    k rollout status deployment/backend -n "$NAMESPACE" --timeout=180s

    echo "Rollback complete. Current state:"
    k get pods -n "$NAMESPACE"
}

# ─── ROLLBACK VỀ REVISION CỤ THỂ ─────────────────────────────────────────
rollback_to_revision() {
    FRONTEND_REV="$1"
    BACKEND_REV="$2"

    if [ -z "$FRONTEND_REV" ] || [ -z "$BACKEND_REV" ]; then
        echo "Usage: rollback_to_revision <frontend_rev> <backend_rev>"
        echo "       Run show_history first to see available revisions"
        exit 1
    fi

    echo ""
    echo "[3] Rolling back to specific revisions..."
    echo "   Frontend → revision $FRONTEND_REV"
    echo "   Backend  → revision $BACKEND_REV"

    k rollout undo deployment/frontend \
        -n "$NAMESPACE" \
        --to-revision="$FRONTEND_REV"

    k rollout undo deployment/backend \
        -n "$NAMESPACE" \
        --to-revision="$BACKEND_REV"

    k rollout status deployment/frontend -n "$NAMESPACE" --timeout=180s
    k rollout status deployment/backend -n "$NAMESPACE" --timeout=180s

    echo "Targeted rollback complete."
}

# ─── ROLLBACK VỀ IMAGE TAG CỤ THỂ ────────────────────────────────────────
rollback_to_image_tag() {
    DOCKER_USER="$1"
    TAG="$2"

    if [ -z "$DOCKER_USER" ] || [ -z "$TAG" ]; then
        echo "Usage: rollback_to_image_tag <dockerhub_user> <commit_sha>"
        exit 1
    fi

    echo ""
    echo "[4] Forcing rollback to specific image tag: $TAG"

    # Patch image trực tiếp — không cần đi qua file YAML
    k set image deployment/frontend \
        frontend="$DOCKER_USER/frontend:$TAG" \
        -n "$NAMESPACE"

    k set image deployment/backend \
        backend="$DOCKER_USER/backend:$TAG" \
        -n "$NAMESPACE"

    k rollout status deployment/frontend -n "$NAMESPACE" --timeout=180s
    k rollout status deployment/backend -n "$NAMESPACE" --timeout=180s

    echo "Forced rollback to image tag $TAG complete."
}

# ─── 5. VERIFY SAU ROLLBACK ──────────────────────────────────────────────────
verify_after_rollback() {
    echo ""
    echo "[5] Verifying cluster state after rollback..."

    echo "--- Pods ---"
    k get pods -n "$NAMESPACE" -o wide

    echo ""
    echo "--- Current images running ---"
    k get pods -n "$NAMESPACE" -o jsonpath=\
"{range .items[*]}{.metadata.name}{'\t'}{.spec.containers[*].image}{'\n'}{end}"

    echo ""
    echo "--- Deployment rollout history ---"
    k rollout history deployment/frontend -n "$NAMESPACE"
    k rollout history deployment/backend -n "$NAMESPACE"

    echo ""
    echo "--- Health check ---"
    DOMAIN="app.nhibuaa.space"
    if [ "$NAMESPACE" == "staging" ]; then
        DOMAIN="staging.nhibuaa.space"
    fi

    HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" \
        "https://$DOMAIN/healthz" || echo "000")
    echo "HTTPS health check: HTTP $HTTP_STATUS"

    # if [ "$HTTP_STATUS" == "200" ]; then
    #     echo "Application is healthy after rollback"
    # else
    #     echo "Application still unhealthy after rollback! (HTTP $HTTP_STATUS)"
    #     echo "Check logs: k logs -n $NAMESPACE -l app=backend --tail=50"
    # fi
}

# ─── MAIN MENU ────────────────────────────────────────────────────────────────
case "${2:-menu}" in
    history)
        show_history
        ;;
    undo)
        show_history
        rollback_one_step
        verify_after_rollback
        ;;
    revision)
        show_history
        rollback_to_revision "$3" "$4"
        verify_after_rollback
        ;;
    tag)
        rollback_to_image_tag "$3" "$4"
        verify_after_rollback
        ;;
    verify)
        verify_after_rollback
        ;;
    *)
        echo ""
        echo "USAGE:"
        echo "  ./rollback.sh [namespace] [command] [args...]"
        echo ""
        echo "COMMANDS:"
        echo "  history              — Xem lịch sử revisions"
        echo "  undo                 — Rollback 1 bước (về revision liền trước)"
        echo "  revision <fe> <be>   — Rollback về revision số cụ thể"
        echo "  tag <user> <sha>     — Rollback về image tag (commit SHA)"
        echo "  verify               — Kiểm tra trạng thái sau rollback"
        echo ""
        echo "EXAMPLES:"
        echo "  ./rollback.sh production history"
        echo "  ./rollback.sh production undo"
        echo "  ./rollback.sh production revision 5 3"
        echo "  ./rollback.sh production tag myuser a1b2c3d4e5f6"
        echo "  ./rollback.sh staging verify"
        ;;
esac
