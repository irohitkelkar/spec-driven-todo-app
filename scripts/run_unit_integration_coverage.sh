#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

RUN_ID="${RUN_ID:-$(timestamp_now)}"
REPORT_DIR="${REPORT_DIR:-$ROOT_DIR/reports/unit_integration_coverage/$RUN_ID}"
UNIT_DIR="$REPORT_DIR/unit_tests"
INTEGRATION_DIR="$REPORT_DIR/integration_tests"
COVERAGE_DIR="$REPORT_DIR/coverage"
REPORT_PATH="$REPORT_DIR/report.md"

mkdir -p "$UNIT_DIR" "$INTEGRATION_DIR" "$COVERAGE_DIR"

log "PHASE 1/4: Prepare dependencies"
flutter pub get

log "PHASE 2/4: Run unit tests"
"$ROOT_DIR/scripts/tasks/run_test_suite.sh" unit test/unit "$UNIT_DIR"
source "$UNIT_DIR/status.env"

log "PHASE 3/4: Run integration tests"
DEVICE_ID="$("$ROOT_DIR/scripts/tasks/ensure_android_emulator.sh")"
"$ROOT_DIR/scripts/tasks/run_test_suite.sh" integration integration_test/coverage_flow_test.dart "$INTEGRATION_DIR" "$DEVICE_ID"
source "$INTEGRATION_DIR/status.env"

log "PHASE 4/4: Generate coverage"
DEVICE_ID="$DEVICE_ID" "$ROOT_DIR/scripts/tasks/generate_coverage.sh" "$COVERAGE_DIR" test/unit integration_test/coverage_flow_test.dart
source "$COVERAGE_DIR/coverage_status.env"

{
  echo "# Unit + Integration Coverage Report"
  echo
  echo "- Run ID: $RUN_ID"
  echo "- Unit tests: $UNIT_STATUS (${UNIT_PASS_PERCENT}% pass, $UNIT_PASSED/$UNIT_EXECUTED)"
  echo "- Integration tests: $INTEGRATION_STATUS (${INTEGRATION_PASS_PERCENT}% pass, $INTEGRATION_PASSED/$INTEGRATION_EXECUTED)"
  echo "- Overall coverage (union): ${COVERAGE_PERCENT}% (${COVERAGE_LINES_HIT}/${COVERAGE_LINES_FOUND})"
  echo
  echo "## Artifacts"
  echo
  echo "- [unit status](unit_tests/status.env)"
  echo "- [integration status](integration_tests/status.env)"
  echo "- [coverage status](coverage/coverage_status.env)"
  echo "- [lcov.info](coverage/lcov.info)"
} >"$REPORT_PATH"

log "SUCCESS: Unit + integration + coverage complete."
log "Artifacts: $REPORT_DIR"
