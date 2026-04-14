#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Usage: $0 <suite_name> <target> <output_dir> [device_id]"
  exit 1
fi

SUITE_NAME="$1"
TARGET="$2"
OUT_DIR="$3"
DEVICE_ID="${4:-}"

PREFIX="$(echo "$SUITE_NAME" | tr '[:lower:]-' '[:upper:]_')"
MACHINE_LOG="$OUT_DIR/${SUITE_NAME}.machine.log"
STATUS_FILE="$OUT_DIR/status.env"
STDOUT_LOG="$OUT_DIR/${SUITE_NAME}.stdout.log"

mkdir -p "$OUT_DIR"

log "Running $SUITE_NAME tests: $TARGET"
set +e
if [ -n "$DEVICE_ID" ]; then
  flutter test --machine -d "$DEVICE_ID" "$TARGET" | tee "$MACHINE_LOG" | tee "$STDOUT_LOG"
  CMD_EXIT_CODE=${PIPESTATUS[0]}
else
  flutter test --machine "$TARGET" | tee "$MACHINE_LOG" | tee "$STDOUT_LOG"
  CMD_EXIT_CODE=${PIPESTATUS[0]}
fi
set -e

IFS='|' read -r TOTAL EXECUTED PASSED FAILED SKIPPED PASS_PERCENT FAIL_PERCENT <<<"$(parse_machine_results "$MACHINE_LOG")"

STATUS="PASS"
if [ "$CMD_EXIT_CODE" -ne 0 ]; then
  STATUS="FAIL"
fi

{
  echo "${PREFIX}_STATUS=$STATUS"
  echo "${PREFIX}_TARGET=$TARGET"
  echo "${PREFIX}_TOTAL=$TOTAL"
  echo "${PREFIX}_EXECUTED=$EXECUTED"
  echo "${PREFIX}_PASSED=$PASSED"
  echo "${PREFIX}_FAILED=$FAILED"
  echo "${PREFIX}_SKIPPED=$SKIPPED"
  echo "${PREFIX}_PASS_PERCENT=$PASS_PERCENT"
  echo "${PREFIX}_FAIL_PERCENT=$FAIL_PERCENT"
  echo "${PREFIX}_MACHINE_LOG=$MACHINE_LOG"
  echo "${PREFIX}_STDOUT_LOG=$STDOUT_LOG"
} >"$STATUS_FILE"

if [ "$CMD_EXIT_CODE" -ne 0 ]; then
  fail "$SUITE_NAME tests failed."
fi

log "$SUITE_NAME tests completed successfully."
