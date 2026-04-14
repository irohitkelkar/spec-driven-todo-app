#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

RUN_ID="${RUN_ID:-$(timestamp_now)}"
REPORT_DIR="${REPORT_DIR:-$ROOT_DIR/reports/integration_screenshots_coverage/$RUN_ID}"
SCREENSHOT_DIR="$REPORT_DIR/screenshots"
COVERAGE_DIR="$REPORT_DIR/coverage"
REPORT_PATH="$REPORT_DIR/report.md"

mkdir -p "$SCREENSHOT_DIR" "$COVERAGE_DIR"

log "PHASE 1/4: Prepare dependencies"
flutter pub get

log "PHASE 2/4: Build debug app"
flutter build apk --debug

log "PHASE 3/4: Capture integration screenshots"
DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")"
"$ROOT_DIR/scripts/tasks/run_integration_screenshots.sh" "$SCREENSHOT_DIR" "$DEVICE_ID"
source "$REPORT_DIR/screenshots_status.env"

log "PHASE 4/4: Generate integration coverage"
DEVICE_ID="$DEVICE_ID" "$ROOT_DIR/scripts/tasks/generate_coverage.sh" "$COVERAGE_DIR" integration_test/coverage_flow_test.dart
source "$COVERAGE_DIR/coverage_status.env"

{
  echo "# Integration Screenshots + Coverage Report"
  echo
  echo "- Run ID: $RUN_ID"
  echo "- Device: $SCREENSHOTS_DEVICE_ID"
  echo "- Screenshot capture: $SCREENSHOTS_STATUS ($SCREENSHOTS_COUNT files)"
  echo "- Integration coverage: ${COVERAGE_PERCENT}% (${COVERAGE_LINES_HIT}/${COVERAGE_LINES_FOUND})"
  echo
  echo "## Artifacts"
  echo
  echo "- [screenshot status](screenshots_status.env)"
  echo "- [coverage status](coverage/coverage_status.env)"
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

log "SUCCESS: Integration screenshots + coverage complete."
log "Artifacts: $REPORT_DIR"
