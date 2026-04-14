#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <screenshot_dir> [device_id]"
  exit 1
fi

SCREENSHOT_DIR="$1"
DEVICE_ID="${2:-}"
STATUS_FILE="$(dirname "$SCREENSHOT_DIR")/screenshots_status.env"
DRIVE_LOG="$(dirname "$SCREENSHOT_DIR")/screenshots_drive.log"

if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")"
fi

mkdir -p "$SCREENSHOT_DIR"

log "Running integration screenshot flow on $DEVICE_ID"
set +e
SCREENSHOT_DIR="$SCREENSHOT_DIR" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d "$DEVICE_ID" | tee "$DRIVE_LOG"
DRIVE_EXIT_CODE=${PIPESTATUS[0]}
set -e

SCREENSHOT_COUNT="$(find "$SCREENSHOT_DIR" -type f -name '*.png' | wc -l | tr -d ' ')"
STATUS="PASS"
if [ "$DRIVE_EXIT_CODE" -ne 0 ] || [ "$SCREENSHOT_COUNT" -lt 8 ]; then
  STATUS="FAIL"
fi

{
  echo "SCREENSHOTS_STATUS=$STATUS"
  echo "SCREENSHOTS_DEVICE_ID=$DEVICE_ID"
  echo "SCREENSHOTS_COUNT=$SCREENSHOT_COUNT"
  echo "SCREENSHOTS_DIR=$SCREENSHOT_DIR"
  echo "SCREENSHOTS_DRIVE_LOG=$DRIVE_LOG"
} >"$STATUS_FILE"

if [ "$STATUS" != "PASS" ]; then
  fail "Integration screenshots flow failed."
fi

log "Integration screenshot flow completed successfully."
