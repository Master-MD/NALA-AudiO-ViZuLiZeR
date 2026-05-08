#!/usr/bin/env bash
set -euo pipefail

APP_NAME="NALA-AudiO-ViZuLiZeR"
SRC_ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="/Users/ultramacuser/Downloads/NALA-AudiO-ViZuLiZeR-Release"
APP_BUNDLE="$OUT_DIR/$APP_NAME.app"
DMG_ROOT="$OUT_DIR/DMGRoot"
ICON_SOURCE="/Users/ultramacuser/Downloads/NALA-AudioO-Visualizer-ICON/NALA-AudioO-Visualizer-ICON-ChatGPT.png"
ICONSET="$OUT_DIR/$APP_NAME.iconset"

swift build -c release --package-path "$SRC_ROOT"

rm -rf "$OUT_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$ICONSET" "$DMG_ROOT"

cp "$SRC_ROOT/.build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ICON_SOURCE" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$((size * 2))" "$((size * 2))" "$ICON_SOURCE" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

/usr/libexec/PlistBuddy -c "Clear dict" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.nala.audio-visualizer" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.3.5" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$APP_BUNDLE/Contents/Info.plist"

codesign --force --deep --sign - "$APP_BUNDLE"

cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDZO "$OUT_DIR/$APP_NAME.dmg"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
hdiutil verify "$OUT_DIR/$APP_NAME.dmg"

echo "$OUT_DIR/$APP_NAME.dmg"
