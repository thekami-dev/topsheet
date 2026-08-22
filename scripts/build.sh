#!/usr/bin/env bash
set -euo pipefail

TARGET=$(gum choose "apk" "appbundle" "ios" "linux" "web" "windows" "macos")
flutter build "$TARGET"
