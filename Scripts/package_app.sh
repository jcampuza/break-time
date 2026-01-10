#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BreakTime"
CONFIGURATION="${1:-debug}"
APP_DIR="$ROOT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SRC="$ROOT_DIR/assets/AppIcon.icns"
ICON_DEST="$RESOURCES_DIR/AppIcon.icns"

ARCHES_INPUT="${ARCHES:-$(uname -m)}"
IFS=' ' read -r -a ARCHES_LIST <<< "${ARCHES_INPUT}"

log() { printf '%s\n' "$*"; }

build_single_arch() {
  local arch="$1"
  log "==> swift build (-c ${CONFIGURATION}, arch ${arch})"
  swift build -c "${CONFIGURATION}" --arch "${arch}"
}

build_multi_arch() {
  local build_paths=()
  for arch in "${ARCHES_LIST[@]}"; do
    local build_path="$ROOT_DIR/.build/${CONFIGURATION}-${arch}"
    log "==> swift build (-c ${CONFIGURATION}, arch ${arch})"
    swift build -c "${CONFIGURATION}" --arch "${arch}" --build-path "${build_path}"
    build_paths+=("${build_path}/${CONFIGURATION}/${APP_NAME}")
  done

  local universal_dir="$ROOT_DIR/.build/${CONFIGURATION}"
  mkdir -p "${universal_dir}"
  log "==> lipo universal binary"
  lipo -create "${build_paths[@]}" -output "${universal_dir}/${APP_NAME}"
}

if [[ "${CONFIGURATION}" != "debug" && "${CONFIGURATION}" != "release" ]]; then
  printf 'ERROR: unknown configuration %s\n' "${CONFIGURATION}" >&2
  exit 1
fi

if [[ "${#ARCHES_LIST[@]}" -le 1 ]]; then
  build_single_arch "${ARCHES_LIST[0]}"
else
  build_multi_arch
fi

BUILD_DIR="$ROOT_DIR/.build/${CONFIGURATION}"
BIN_PATH="$BUILD_DIR/$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$ICON_SRC" "$ICON_DEST"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>BreakTime</string>
    <key>CFBundleIdentifier</key>
    <string>com.breaktime.app</string>
    <key>CFBundleName</key>
    <string>BreakTime</string>
    <key>CFBundleDisplayName</key>
    <string>BreakTime</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>BreakTime uses Accessibility to manage break reminders.</string>
</dict>
</plist>
PLIST

if [[ "${BREAKTIME_SIGNING:-}" == "adhoc" ]]; then
  log "==> codesign (adhoc)"
  codesign --force --deep --sign - "$APP_DIR"
fi

log "Packaged $APP_DIR"
