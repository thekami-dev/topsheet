#!/usr/bin/env bash
set -euo pipefail

AVD="buskhoja"
DEVICE="emulator-5554"

# adb kill-server >/dev/null 2>&1 || true
# pkill -f "emulator.*-avd $AVD" >/dev/null 2>&1 || true

# QT_QPA_PLATFORM=xcb emulator -avd "$AVD" -no-snapshot-load &

# adb wait-for-device
# until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
#   sleep 1
# done

# raise_emulator_window() {
#   command -v xdotool >/dev/null 2>&1 || return 0
#   for _ in $(seq 1 20); do
#     wid=$(xdotool search --name "Android Emulator" | head -1) && [ -n "$wid" ] && break
#     sleep 0.5
#   done
#   [ -n "${wid:-}" ] && xdotool windowmap "$wid" windowactivate "$wid" >/dev/null 2>&1
#   return 0
# }
# raise_emulator_window

flutter run -d "$DEVICE"
