#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <video_dir> <screenshot_dir> [device_id]"
  exit 1
fi

VIDEO_DIR="$1"
SCREENSHOT_DIR="$2"
DEVICE_ID="${3:-}"

REMOTE_VIDEO_PATH="/sdcard/full_run.mp4"
VIDEO_PATH="$VIDEO_DIR/full_run.mp4"
STATUS_FILE="$(dirname "$VIDEO_DIR")/video_status.env"
DRIVE_LOG="$(dirname "$VIDEO_DIR")/video_drive.log"
RECORD_PID=""

cleanup() {
  if [ -n "$RECORD_PID" ] && kill -0 "$RECORD_PID" >/dev/null 2>&1; then
    log "Stopping emulator recording"
    kill -INT "$RECORD_PID" >/dev/null 2>&1 || true
    wait "$RECORD_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT

if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")"
fi

mkdir -p "$VIDEO_DIR" "$SCREENSHOT_DIR"

adb -s "$DEVICE_ID" shell rm -f "$REMOTE_VIDEO_PATH" >/dev/null 2>&1 || true

log "Starting emulator recording on $DEVICE_ID"
adb -s "$DEVICE_ID" shell screenrecord "$REMOTE_VIDEO_PATH" >/dev/null 2>&1 &
RECORD_PID=$!
sleep 2
kill -0 "$RECORD_PID" >/dev/null 2>&1 || fail "Failed to start emulator recording."

log "Running integration flow for video capture"
set +e
SCREENSHOT_DIR="$SCREENSHOT_DIR" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d "$DEVICE_ID" | tee "$DRIVE_LOG"
DRIVE_EXIT_CODE=${PIPESTATUS[0]}
set -e

cleanup
RECORD_PID=""

adb -s "$DEVICE_ID" pull "$REMOTE_VIDEO_PATH" "$VIDEO_PATH" >/dev/null

SCREENSHOT_COUNT="$(find "$SCREENSHOT_DIR" -type f -name '*.png' | wc -l | tr -d ' ')"
VIDEO_SIZE=0
if [ -f "$VIDEO_PATH" ]; then
  VIDEO_SIZE="$(wc -c < "$VIDEO_PATH" | tr -d ' ')"
fi

STATUS="PASS"
if [ "$DRIVE_EXIT_CODE" -ne 0 ] || [ "$SCREENSHOT_COUNT" -lt 8 ] || [ "$VIDEO_SIZE" -le 0 ]; then
  STATUS="FAIL"
fi

{
  echo "VIDEO_STATUS=$STATUS"
  echo "VIDEO_DEVICE_ID=$DEVICE_ID"
  echo "VIDEO_PATH=$VIDEO_PATH"
  echo "VIDEO_SIZE=$VIDEO_SIZE"
  echo "VIDEO_SCREENSHOT_COUNT=$SCREENSHOT_COUNT"
  echo "VIDEO_DRIVE_LOG=$DRIVE_LOG"
} >"$STATUS_FILE"

if [ "$STATUS" != "PASS" ]; then
  fail "Integration video flow failed."
fi

log "Integration video flow completed successfully."
