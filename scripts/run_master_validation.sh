#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

RUN_ID="${RUN_ID:-$(timestamp_now)}"
REPORT_DIR="${REPORT_DIR:-$ROOT_DIR/reports/master_validation/$RUN_ID}"
UNIT_DIR="$REPORT_DIR/unit_tests"
WIDGET_DIR="$REPORT_DIR/widget_tests"
INTEGRATION_DIR="$REPORT_DIR/integration_tests"
COVERAGE_DIR="$REPORT_DIR/coverage"
SCREENSHOT_DIR="$REPORT_DIR/screenshots"
VIDEO_DIR="$REPORT_DIR/video"
SUMMARY_PATH="$REPORT_DIR/summary_report.md"

mkdir -p "$UNIT_DIR" "$WIDGET_DIR" "$INTEGRATION_DIR" "$COVERAGE_DIR" "$SCREENSHOT_DIR" "$VIDEO_DIR"

OVERALL_STATUS="PASS"

checkbox_for() {
  if [ "${1:-NOT_RUN}" = "PASS" ]; then
    printf '[x]'
  else
    printf '[ ]'
  fi
}

run_step() {
  local step_name="$1"
  shift
  if "$@"; then
    return 0
  fi
  log "Step failed: $step_name"
  OVERALL_STATUS="FAIL"
  return 1
}

log "MASTER PHASE 1/8: Prepare dependencies"
flutter pub get || OVERALL_STATUS="FAIL"

log "MASTER PHASE 2/8: Run unit tests"
run_step "unit tests" "$ROOT_DIR/scripts/tasks/run_test_suite.sh" unit test/unit "$UNIT_DIR" || true
[ -f "$UNIT_DIR/status.env" ] && source "$UNIT_DIR/status.env"

log "MASTER PHASE 3/8: Run widget tests"
run_step "widget tests" "$ROOT_DIR/scripts/tasks/run_test_suite.sh" widget test/widget_test.dart "$WIDGET_DIR" || true
[ -f "$WIDGET_DIR/status.env" ] && source "$WIDGET_DIR/status.env"

log "MASTER PHASE 4/8: Ensure Android emulator"
DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")" || OVERALL_STATUS="FAIL"

log "MASTER PHASE 5/8: Run integration tests"
if [ -n "${DEVICE_ID:-}" ]; then
  run_step "integration tests" "$ROOT_DIR/scripts/tasks/run_test_suite.sh" integration integration_test/coverage_flow_test.dart "$INTEGRATION_DIR" "$DEVICE_ID" || true
fi
[ -f "$INTEGRATION_DIR/status.env" ] && source "$INTEGRATION_DIR/status.env"

log "MASTER PHASE 6/8: Generate overall coverage"
if [ -n "${DEVICE_ID:-}" ]; then
  run_step "coverage generation" env DEVICE_ID="$DEVICE_ID" "$ROOT_DIR/scripts/tasks/generate_coverage.sh" "$COVERAGE_DIR" test/unit test/widget_test.dart integration_test/coverage_flow_test.dart || true
fi
[ -f "$COVERAGE_DIR/coverage_status.env" ] && source "$COVERAGE_DIR/coverage_status.env"

log "MASTER PHASE 7/8: Capture screenshot validation run"
if [ -n "${DEVICE_ID:-}" ]; then
  run_step "screenshot validation" "$ROOT_DIR/scripts/tasks/run_integration_screenshots.sh" "$SCREENSHOT_DIR" "$DEVICE_ID" || true
fi
[ -f "$REPORT_DIR/screenshots_status.env" ] && source "$REPORT_DIR/screenshots_status.env"

log "MASTER PHASE 8/8: Capture video validation run"
if [ -n "${DEVICE_ID:-}" ]; then
  run_step "video validation" "$ROOT_DIR/scripts/tasks/run_integration_video.sh" "$VIDEO_DIR" "$SCREENSHOT_DIR" "$DEVICE_ID" || true
fi
[ -f "$REPORT_DIR/video_status.env" ] && source "$REPORT_DIR/video_status.env"

SCREENSHOT_COUNT_FINAL="${SCREENSHOTS_COUNT:-0}"
if [ -n "${VIDEO_SCREENSHOT_COUNT:-}" ] && [ "$VIDEO_SCREENSHOT_COUNT" -gt "$SCREENSHOT_COUNT_FINAL" ]; then
  SCREENSHOT_COUNT_FINAL="$VIDEO_SCREENSHOT_COUNT"
fi

{
  echo "# Master Validation Summary"
  echo
  echo "- Run ID: $RUN_ID"
  echo "- Overall status: $OVERALL_STATUS"
  echo
  echo "## Checklist"
  echo
  echo "- $(checkbox_for "${UNIT_STATUS:-NOT_RUN}") Unit tests passed: ${UNIT_STATUS:-NOT_RUN} (${UNIT_PASS_PERCENT:-0.00}% pass, ${UNIT_PASSED:-0}/${UNIT_EXECUTED:-0})"
  echo "- $(checkbox_for "${WIDGET_STATUS:-NOT_RUN}") Widget tests passed: ${WIDGET_STATUS:-NOT_RUN} (${WIDGET_PASS_PERCENT:-0.00}% pass, ${WIDGET_PASSED:-0}/${WIDGET_EXECUTED:-0})"
  echo "- $(checkbox_for "${INTEGRATION_STATUS:-NOT_RUN}") Integration tests passed: ${INTEGRATION_STATUS:-NOT_RUN} (${INTEGRATION_PASS_PERCENT:-0.00}% pass, ${INTEGRATION_PASSED:-0}/${INTEGRATION_EXECUTED:-0})"
  echo "- $(checkbox_for "${COVERAGE_STATUS:-NOT_RUN}") Overall test coverage generated: ${COVERAGE_STATUS:-NOT_RUN} (${COVERAGE_PERCENT:-0.00}% , ${COVERAGE_LINES_HIT:-0}/${COVERAGE_LINES_FOUND:-0})"
  echo "- $(checkbox_for "${SCREENSHOTS_STATUS:-NOT_RUN}") Screenshots generated: ${SCREENSHOTS_STATUS:-NOT_RUN} (${SCREENSHOT_COUNT_FINAL} files)"
  echo "- $(checkbox_for "${VIDEO_STATUS:-NOT_RUN}") Full run video generated: ${VIDEO_STATUS:-NOT_RUN} (${VIDEO_SIZE:-0} bytes)"
  echo
  echo "## Artifacts"
  echo
  echo "- [unit status](unit_tests/status.env)"
  echo "- [widget status](widget_tests/status.env)"
  echo "- [integration status](integration_tests/status.env)"
  echo "- [coverage status](coverage/coverage_status.env)"
  echo "- [coverage lcov](coverage/lcov.info)"
  echo "- [screenshots status](screenshots_status.env)"
  echo "- [video status](video_status.env)"
  echo "- [screenshots directory](screenshots)"
  echo "- [video file](video/full_run.mp4)"
} >"$SUMMARY_PATH"

log "MASTER SUMMARY: $SUMMARY_PATH"
log "Artifacts: $REPORT_DIR"

if [ "$OVERALL_STATUS" != "PASS" ]; then
  fail "Master validation completed with failures."
fi
