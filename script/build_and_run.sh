#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="LocalSend"
BUNDLE_ID="org.localsend.localsendApp"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACOS_DIR="$ROOT_DIR/app/macos"
DERIVED_DATA="$ROOT_DIR/app/build/codex-run-macos"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
  xcodebuild \
    -quiet \
    -workspace "$MACOS_DIR/Runner.xcworkspace" \
    -scheme Runner \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
