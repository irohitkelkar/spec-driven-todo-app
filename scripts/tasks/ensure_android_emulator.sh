#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/common.sh"

EMULATOR_NAME="${1:-${EMULATOR_NAME:-Pixel_5_API_34}}"
EMULATOR_BIN="${2:-${EMULATOR_BIN:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}/emulator/emulator}}"
MAX_RETRIES="${3:-${MAX_RETRIES:-3}}"

DEVICE_ID="$(ensure_android_emulator "$EMULATOR_NAME" "$EMULATOR_BIN" "$MAX_RETRIES")" || fail "Unable to prepare Android emulator."
log "Emulator ready: $DEVICE_ID"
printf '%s\n' "$DEVICE_ID"
