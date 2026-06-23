#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/MarkdownStudio.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE="$ROOT_DIR/.build/release/MarkdownStudio"
APP_VERSION="${MARKDOWNSTUDIO_VERSION:-0.1.0}"
APP_BUILD="${MARKDOWNSTUDIO_BUILD:-1}"

if [[ ! -x "$EXECUTABLE" ]]; then
  EXECUTABLE="$ROOT_DIR/.build/debug/MarkdownStudio"
fi

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Missing executable: $EXECUTABLE"
  echo "Run: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release"
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"
cp "$EXECUTABLE" "$MACOS_DIR/MarkdownStudio"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/MarkdownStudio" 2>/dev/null || true
install_name_tool -delete_rpath "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-6.2/macosx" "$MACOS_DIR/MarkdownStudio" 2>/dev/null || true

xcrun swift-stdlib-tool \
  --copy \
  --scan-executable "$MACOS_DIR/MarkdownStudio" \
  --platform macosx \
  --unsigned-destination "$FRAMEWORKS_DIR" \
  >/dev/null

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>MarkdownStudio</string>
  <key>CFBundleIdentifier</key>
  <string>local.markdownstudio.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MarkdownStudio</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticTermination</key>
  <true/>
  <key>NSSupportsSuddenTermination</key>
  <true/>
</dict>
</plist>
PLIST

echo "$APP_DIR"
