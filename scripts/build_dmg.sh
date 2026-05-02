#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-NotchClick}"
APP_PATH="${1:-${APP_PATH:-$PWD/dist/$APP_NAME.app}}"
OUTPUT_DMG="${2:-${OUTPUT_DMG:-$PWD/dist/$APP_NAME.dmg}}"
VOLUME_NAME="${VOLUME_NAME:-$APP_NAME}"
BACKGROUND_SVG="${BACKGROUND_SVG:-$PWD/scripts/assets/notchclick-dmg-background.svg}"
SVG_RENDERER_SWIFT="${SVG_RENDERER_SWIFT:-$PWD/scripts/render_svg_to_png.swift}"
WINDOW_BOUNDS="${WINDOW_BOUNDS:-100,100,660,400}"
APP_ICON_POS="${APP_ICON_POS:-170,125}"
APPLICATIONS_ICON_POS="${APPLICATIONS_ICON_POS:-390,125}"
REQUIRE_VALID_CODESIGN="${REQUIRE_VALID_CODESIGN:-1}"
BACKGROUND_NAME="background.png"
IFS=',' read -r WB1 WB2 WB3 WB4 <<<"$WINDOW_BOUNDS"
WINDOW_WIDTH=$((WB3 - WB1))
WINDOW_HEIGHT=$((WB4 - WB2))

usage() {
    cat <<'EOF'
Build a drag-to-Applications DMG for NotchClick.

Usage:
  ./scripts/build_dmg.sh [APP_PATH] [OUTPUT_DMG]

Defaults:
  APP_PATH    ./dist/NotchClick.app
  OUTPUT_DMG  ./dist/NotchClick.dmg
EOF
}

note() {
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
    echo "error: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

need_cmd hdiutil
need_cmd osascript
need_cmd ditto
need_cmd xcrun
if [[ "$REQUIRE_VALID_CODESIGN" == "1" ]]; then
    need_cmd codesign
fi

[[ -d "$APP_PATH" ]] || die "App bundle not found at $APP_PATH"
[[ -f "$BACKGROUND_SVG" ]] || die "Background asset not found at $BACKGROUND_SVG"
[[ -f "$SVG_RENDERER_SWIFT" ]] || die "SVG renderer source not found at $SVG_RENDERER_SWIFT"

if [[ "$REQUIRE_VALID_CODESIGN" == "1" ]]; then
    note "Verifying app signature before packaging"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH" ||
        die "App signature is not valid. Rebuild a signed app before creating a public DMG, or set REQUIRE_VALID_CODESIGN=0 for layout-only testing."
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/notchclick-dmg.XXXXXX")"
STAGE_DIR="$TMP_ROOT/stage"
MOUNT_DIR="$TMP_ROOT/mount"
RENDER_DIR="$TMP_ROOT/rendered"
RW_DMG="$TMP_ROOT/$APP_NAME-rw.dmg"
SVG_RENDERER_BIN="$TMP_ROOT/render-svg"
DEVICE=""

cleanup() {
    if [[ -n "$DEVICE" ]]; then
        hdiutil detach "$DEVICE" -quiet -force >/dev/null 2>&1 || true
    elif mount | grep -q "on $MOUNT_DIR "; then
        hdiutil detach "$MOUNT_DIR" -quiet -force >/dev/null 2>&1 || true
    fi
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$STAGE_DIR/.background" "$MOUNT_DIR" "$RENDER_DIR"

note "Rendering DMG background"
xcrun swiftc -framework AppKit "$SVG_RENDERER_SWIFT" -o "$SVG_RENDERER_BIN"
RENDERED_BACKGROUND="$RENDER_DIR/$BACKGROUND_NAME"
"$SVG_RENDERER_BIN" "$BACKGROUND_SVG" "$RENDERED_BACKGROUND" "$WINDOW_WIDTH" "$WINDOW_HEIGHT"
[[ -f "$RENDERED_BACKGROUND" ]] || die "SVG renderer failed to create $RENDERED_BACKGROUND"
cp "$RENDERED_BACKGROUND" "$STAGE_DIR/.background/$BACKGROUND_NAME"

note "Preparing DMG staging directory"
ditto "$APP_PATH" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

SIZE_MB="$(du -sm "$STAGE_DIR" | awk '{print $1}')"
SIZE_MB=$((SIZE_MB + 40))
rm -f "$OUTPUT_DMG"

note "Creating writable DMG"
hdiutil create \
    -quiet \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -srcfolder "$STAGE_DIR" \
    -format UDRW \
    -size "${SIZE_MB}m" \
    "$RW_DMG"

note "Applying Finder layout"
ATTACH_OUTPUT="$(hdiutil attach "$RW_DMG" -noverify -mountpoint "$MOUNT_DIR")"
DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/^\/dev\// {print $1; exit}')"
[[ -n "$DEVICE" ]] || die "Failed to attach writable DMG"

IFS=',' read -r APP_X APP_Y <<<"$APP_ICON_POS"
IFS=',' read -r APPS_X APPS_Y <<<"$APPLICATIONS_ICON_POS"

osascript <<EOF
set dmgFolder to POSIX file "$MOUNT_DIR" as alias
tell application "Finder"
    tell folder dmgFolder
        open
        delay 0.5
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {$WB1, $WB2, $WB3, $WB4}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set text size of viewOptions to 14
        set background picture of viewOptions to file ".background:$BACKGROUND_NAME"
        set position of item "$APP_NAME.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF

sync
sleep 1
hdiutil detach "$DEVICE" -quiet
DEVICE=""

note "Compressing final DMG"
hdiutil convert "$RW_DMG" -quiet -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG"

note "DMG ready"
echo "$OUTPUT_DMG"
