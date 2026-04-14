#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

RUN_ID="${RUN_ID:-$(timestamp_now)}"
REPORT_DIR="${REPORT_DIR:-$ROOT_DIR/reports/integration_video_coverage/$RUN_ID}"
SCREENSHOT_DIR="$REPORT_DIR/screenshots"
VIDEO_DIR="$REPORT_DIR/video"
COVERAGE_DIR="$REPORT_DIR/coverage"
REPORT_PATH="$REPORT_DIR/report.md"

mkdir -p "$SCREENSHOT_DIR" "$VIDEO_DIR" "$COVERAGE_DIR"

log "PHASE 1/4: Prepare dependencies"
flutter pub get

log "PHASE 2/4: Build debug app"
flutter build apk --debug

log "PHASE 3/4: Capture integration video session"
DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")"
"$ROOT_DIR/scripts/tasks/run_integration_video.sh" "$VIDEO_DIR" "$SCREENSHOT_DIR" "$DEVICE_ID"
source "$REPORT_DIR/video_status.env"

log "PHASE 4/4: Generate integration coverage"
DEVICE_ID="$DEVICE_ID" "$ROOT_DIR/scripts/tasks/generate_coverage.sh" "$COVERAGE_DIR" integration_test/coverage_flow_test.dart
source "$COVERAGE_DIR/coverage_status.env"

{
  echo "# Integration Video + Coverage Report"
  echo
  echo "- Run ID: $RUN_ID"
  echo "- Device: $VIDEO_DEVICE_ID"
  echo "- Video capture: $VIDEO_STATUS"
  echo "- Video size bytes: $VIDEO_SIZE"
  echo "- Screenshots during run: $VIDEO_SCREENSHOT_COUNT"
  echo "- Integration coverage: ${COVERAGE_PERCENT}% (${COVERAGE_LINES_HIT}/${COVERAGE_LINES_FOUND})"
  echo
  echo "## Artifacts"
  echo
  echo "- [video status](video_status.env)"
  echo "- [coverage status](coverage/coverage_status.env)"
  echo "- [full_run.mp4](video/full_run.mp4)"
  echo "- [lcov.info](coverage/lcov.info)"
  echo
  echo "## Screenshots"
  echo
  while IFS= read -r screenshot; do
    base_name="$(basename "$screenshot")"
    echo "### $base_name"
    echo
    echo "![${base_name}](screenshots/${base_name})"
    echo
  done < <(find "$SCREENSHOT_DIR" -type f -name '*.png' | sort)
} >"$REPORT_PATH"

log "SUCCESS: Integration video + coverage complete."
log "Artifacts: $REPORT_DIR"
