#!/usr/bin/env bash

set -euo pipefail

timestamp_now() {
  date '+%Y-%m-%d_%H-%M-%S'
}

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >&2
}

fail() {
  log "ERROR: $1"
  exit 1
}

retry() {
  local description="$1"
  local max_retries="$2"
  shift 2

  local attempt=1
  until "$@"; do
    if [ "$attempt" -ge "$max_retries" ]; then
      log "FAIL: $description after $attempt attempts"
      return 1
    fi
    attempt=$((attempt + 1))
    log "Retrying: $description (attempt $attempt/$max_retries)"
    sleep 2
  done
}

detect_running_emulator() {
  adb devices | awk '$1 ~ /^emulator-[0-9]+$/ && $2 == "device" { print $1; exit }'
}

start_or_attach_emulator() {
  local emulator_name="$1"
  local emulator_bin="$2"
  local device_id

  device_id="$(detect_running_emulator || true)"
  if [ -n "$device_id" ]; then
    echo "$device_id"
    return 0
  fi

  if [ ! -x "$emulator_bin" ]; then
    log "Emulator binary not found: $emulator_bin"
    return 1
  fi

  if ! "$emulator_bin" -list-avds | grep -Fxq "$emulator_name"; then
    log "AVD '$emulator_name' not found."
    return 1
  fi

  log "Starting emulator AVD: $emulator_name"
  "$emulator_bin" @"$emulator_name" -no-snapshot-load -no-boot-anim >/tmp/todo_app_emulator.log 2>&1 &

  for _ in $(seq 1 90); do
    device_id="$(detect_running_emulator || true)"
    if [ -n "$device_id" ]; then
      echo "$device_id"
      return 0
    fi
    sleep 2
  done

  return 1
}

wait_for_emulator_ready() {
  local device_id="$1"
  adb -s "$device_id" wait-for-device

  for _ in $(seq 1 120); do
    local boot_state
    boot_state="$(adb -s "$device_id" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    if [ "$boot_state" = "1" ]; then
      adb -s "$device_id" shell input keyevent 82 >/dev/null 2>&1 || true
      return 0
    fi
    sleep 2
  done

  return 1
}

ensure_android_emulator() {
  local emulator_name="${1:-Pixel_5_API_34}"
  local emulator_bin="${2:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}/emulator/emulator}"
  local retries="${3:-3}"
  local device_id=""

  if ! device_id="$(retry "start or attach emulator" "$retries" start_or_attach_emulator "$emulator_name" "$emulator_bin")"; then
    return 1
  fi

  if ! retry "wait for emulator readiness" "$retries" wait_for_emulator_ready "$device_id"; then
    return 1
  fi

  echo "$device_id"
}

parse_machine_results() {
  local machine_log="$1"
  local total success skipped executed passed failed pass_percent fail_percent

  total="$(awk '/"type":"testDone"/ && /"hidden":false/ {count++} END {print count + 0}' "$machine_log")"
  success="$(awk '/"type":"testDone"/ && /"hidden":false/ && /"result":"success"/ {count++} END {print count + 0}' "$machine_log")"
  skipped="$(awk '/"type":"testDone"/ && /"hidden":false/ && /"skipped":true/ {count++} END {print count + 0}' "$machine_log")"

  executed=$((total - skipped))
  passed=$((success - skipped))
  if [ "$passed" -lt 0 ]; then
    passed=0
  fi
  failed=$((executed - passed))
  if [ "$failed" -lt 0 ]; then
    failed=0
  fi

  pass_percent="$(awk -v p="$passed" -v e="$executed" 'BEGIN { if (e == 0) print "0.00"; else printf "%.2f", (p/e)*100 }')"
  fail_percent="$(awk -v f="$failed" -v e="$executed" 'BEGIN { if (e == 0) print "0.00"; else printf "%.2f", (f/e)*100 }')"

  printf '%s|%s|%s|%s|%s|%s|%s' \
    "$total" "$executed" "$passed" "$failed" "$skipped" "$pass_percent" "$fail_percent"
}

coverage_summary_from_lcov() {
  local lcov_file="$1"
  local lines_found lines_hit percent
  lines_found="$(awk -F: '/^LF:/{sum += $2} END {print sum + 0}' "$lcov_file")"
  lines_hit="$(awk -F: '/^LH:/{sum += $2} END {print sum + 0}' "$lcov_file")"
  percent="$(awk -v found="$lines_found" -v hit="$lines_hit" 'BEGIN { if (found == 0) print "0.00"; else printf "%.2f", (hit/found)*100 }')"
  printf '%s|%s|%s' "$lines_hit" "$lines_found" "$percent"
}

coverage_summary_union() {
  awk '
    /^SF:/ {
      source = substr($0, 4)
      next
    }
    /^DA:/ {
      split(substr($0, 4), parts, ",")
      line = parts[1]
      hits = parts[2] + 0
      key = source ":" line
      if (!(key in line_hits) || hits > line_hits[key]) {
        line_hits[key] = hits
      }
    }
    END {
      total = 0
      covered = 0
      for (key in line_hits) {
        total++
        if (line_hits[key] > 0) {
          covered++
        }
      }
      percent = (total == 0) ? 0 : (covered / total) * 100
      printf "%d|%d|%.2f\n", covered, total, percent
    }
  ' "$@"
}
