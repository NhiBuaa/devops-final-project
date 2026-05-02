#!/bin/bash
# =============================================================================
# IDEMPOTENCY TEST SCRIPT
# Chạy script này để chứng minh idempotency cho báo cáo cuối kỳ
# Output sẽ được lưu vào file log để nộp kèm báo cáo
# =============================================================================

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="./idempotency-logs"
LOG_FILE="${LOG_DIR}/idempotency_test_${TIMESTAMP}.log"
INVENTORY="inventory/hosts.ini"

mkdir -p "$LOG_DIR"

echo "============================================================" | tee -a "$LOG_FILE"
echo "IDEMPOTENCY TEST - $(date)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

# ---- TERRAFORM IDEMPOTENCY ----
echo "" | tee -a "$LOG_FILE"
echo "📋 [STEP 1] TERRAFORM PLAN - Checking for drift..." | tee -a "$LOG_FILE"
echo "------------------------------------------------------------" | tee -a "$LOG_FILE"

cd terraform/
terraform plan -detailed-exitcode 2>&1 | tee -a "../$LOG_FILE"
TF_EXIT=$?

if [ $TF_EXIT -eq 0 ]; then
    echo "" | tee -a "../$LOG_FILE"
    echo "✅ TERRAFORM IDEMPOTENCY CONFIRMED: No changes needed!" | tee -a "../$LOG_FILE"
    echo "   Exit code 0 = Infrastructure matches desired state exactly." | tee -a "../$LOG_FILE"
elif [ $TF_EXIT -eq 2 ]; then
    echo "" | tee -a "../$LOG_FILE"
    echo "⚠️  WARNING: Terraform detected changes (exit code 2)." | tee -a "../$LOG_FILE"
    echo "   This means infrastructure has drifted from desired state." | tee -a "../$LOG_FILE"
fi
cd ..

# ---- ANSIBLE IDEMPOTENCY ----
echo "" | tee -a "$LOG_FILE"
echo "📋 [STEP 2] ANSIBLE PLAYBOOK - Second run (idempotency test)..." | tee -a "$LOG_FILE"
echo "------------------------------------------------------------" | tee -a "$LOG_FILE"
echo "KEY: changed=0 means fully idempotent" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

cd ansible/
ansible-playbook -i "$INVENTORY" site.yml --diff 2>&1 | tee -a "../$LOG_FILE"

# Extract PLAY RECAP
echo "" | tee -a "../$LOG_FILE"
echo "============================================================" | tee -a "../$LOG_FILE"
echo "📊 IDEMPOTENCY ANALYSIS:" | tee -a "../$LOG_FILE"
echo "============================================================" | tee -a "../$LOG_FILE"

grep "PLAY RECAP" -A 20 "../$LOG_FILE" | tail -20 | tee -a "../$LOG_FILE"

echo "" | tee -a "../$LOG_FILE"
echo "INTERPRETATION:" | tee -a "../$LOG_FILE"
echo "  ok=N    : Tasks that verified state (no changes needed)" | tee -a "../$LOG_FILE"
echo "  changed=0: ✅ IDEMPOTENT - No actual changes were made" | tee -a "../$LOG_FILE"
echo "  changed>0: ⚠️  Some tasks made changes (check which ones)" | tee -a "../$LOG_FILE"
echo "  failed=0 : ✅ No errors" | tee -a "../$LOG_FILE"
echo "" | tee -a "../$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "../$LOG_FILE"
echo "Include this log in your final report as idempotency evidence." | tee -a "../$LOG_FILE"
cd ..