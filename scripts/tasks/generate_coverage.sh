#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <coverage_output_dir> <target1> [target2 ...]"
  exit 1
fi

COVERAGE_DIR="$1"
shift
TARGETS=("$@")

STATUS_FILE="$COVERAGE_DIR/coverage_status.env"
COVERAGE_LOG="$COVERAGE_DIR/coverage.log"
MERGED_LCOV="$COVERAGE_DIR/lcov.info"
CONCAT_LCOV="$COVERAGE_DIR/lcov.concat.info"

mkdir -p "$COVERAGE_DIR"
rm -f "$MERGED_LCOV" "$CONCAT_LCOV" "$COVERAGE_LOG"

STATUS="PASS"

for target in "${TARGETS[@]}"; do
  safe_target="$(echo "$target" | tr '/.' '__' | tr -cd '[:alnum:]_')"
  target_lcov="$COVERAGE_DIR/${safe_target}.lcov.info"

  log "Generating coverage for $target" | tee -a "$COVERAGE_LOG"
  set +e
  if [[ "$target" == integration_test/* ]] && [ -n "${DEVICE_ID:-}" ]; then
    flutter test --coverage -d "$DEVICE_ID" "$target" >>"$COVERAGE_LOG" 2>&1
  else
    flutter test --coverage "$target" >>"$COVERAGE_LOG" 2>&1
  fi
  coverage_exit_code=$?
  set -e

  if [ "$coverage_exit_code" -ne 0 ] || [ ! -f "$ROOT_DIR/coverage/lcov.info" ]; then
    STATUS="FAIL"
    break
  fi

  cp "$ROOT_DIR/coverage/lcov.info" "$target_lcov"
  cat "$target_lcov" >>"$CONCAT_LCOV"
done

if [ "$STATUS" = "PASS" ]; then
  cp "$CONCAT_LCOV" "$MERGED_LCOV"
  IFS='|' read -r COVERAGE_LINES_HIT COVERAGE_LINES_FOUND COVERAGE_PERCENT <<<"$(coverage_summary_union "$COVERAGE_DIR"/*.lcov.info)"
else
  COVERAGE_LINES_HIT=0
  COVERAGE_LINES_FOUND=0
  COVERAGE_PERCENT="0.00"
fi

{
  echo "COVERAGE_STATUS=$STATUS"
  echo "COVERAGE_PERCENT=$COVERAGE_PERCENT"
  echo "COVERAGE_LINES_HIT=$COVERAGE_LINES_HIT"
  echo "COVERAGE_LINES_FOUND=$COVERAGE_LINES_FOUND"
  echo "COVERAGE_MERGED_LCOV=$MERGED_LCOV"
  echo "COVERAGE_CONCAT_LCOV=$CONCAT_LCOV"
  echo "COVERAGE_LOG=$COVERAGE_LOG"
} >"$STATUS_FILE"

if [ "$STATUS" != "PASS" ]; then
  fail "Coverage generation failed."
fi

log "Coverage generation completed successfully."
