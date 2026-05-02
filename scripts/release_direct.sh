#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-NotchClick}"
PROJECT_PATH="${PROJECT_PATH:-NotchClick.xcodeproj}"
SCHEME="${SCHEME:-NotchClick}"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-generic/platform=macOS}"
INFO_PLIST_PATH="${INFO_PLIST_PATH:-app/NotchClick/Info.plist}"
DIST_ROOT="${DIST_ROOT:-$PWD/dist}"
TEAM_ID="${TEAM_ID:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_TIMEOUT="${NOTARY_TIMEOUT:-15m}"
ALLOW_PROVISIONING_UPDATES="${ALLOW_PROVISIONING_UPDATES:-0}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
XCODEBUILD_BIN="${XCODEBUILD_BIN:-}"

usage() {
    cat <<'EOF'
Build a Developer ID-signed release for direct distribution.

Required environment variables:
  TEAM_ID            Apple Developer Team ID
  NOTARY_PROFILE     notarytool keychain profile name

Optional environment variables:
  APP_NAME                     defaults to NotchClick
  PROJECT_PATH                 defaults to NotchClick.xcodeproj
  SCHEME                       defaults to NotchClick
  CONFIGURATION                defaults to Release
  DESTINATION                  defaults to generic/platform=macOS
  DIST_ROOT                    defaults to ./dist
  NOTARY_TIMEOUT               defaults to 15m
  ALLOW_PROVISIONING_UPDATES   set to 1 to pass -allowProvisioningUpdates
  SKIP_NOTARIZATION            set to 1 to stop after export/signature checks

Examples:
  TEAM_ID=ABCDE12345 NOTARY_PROFILE=NotchClick-Notary ./scripts/release_direct.sh
  TEAM_ID=ABCDE12345 NOTARY_PROFILE=NotchClick-Notary ALLOW_PROVISIONING_UPDATES=1 ./scripts/release_direct.sh
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

resolve_xcodebuild() {
    if [[ -n "$XCODEBUILD_BIN" ]]; then
        [[ -x "$XCODEBUILD_BIN" ]] || die "XCODEBUILD_BIN is not executable: $XCODEBUILD_BIN"
        printf '%s\n' "$XCODEBUILD_BIN"
        return
    fi

    local selected_developer_dir=""
    if selected_developer_dir="$(xcode-select -p 2>/dev/null)" &&
        [[ "$selected_developer_dir" == *".app/Contents/Developer" ]]; then
        xcodebuild_path="$selected_developer_dir/usr/bin/xcodebuild"
    else
        xcodebuild_path=""
    fi

    if [[ -n "$xcodebuild_path" && -x "$xcodebuild_path" ]]; then
        printf '%s\n' "$xcodebuild_path"
        return
    fi

    if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
        printf '%s\n' "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
        return
    fi

    die "Couldn't find Xcode's xcodebuild. Install Xcode or set XCODEBUILD_BIN."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

[[ -n "$TEAM_ID" ]] || die "Set TEAM_ID before running this script."
[[ -e "$PROJECT_PATH" ]] || die "Project not found at $PROJECT_PATH"
[[ -f "$INFO_PLIST_PATH" ]] || die "Info.plist not found at $INFO_PLIST_PATH"

need_cmd xcrun
need_cmd codesign
need_cmd ditto
need_cmd spctl
need_cmd plutil
need_cmd security
[[ -x /usr/libexec/PlistBuddy ]] || die "Missing /usr/libexec/PlistBuddy"

XCODEBUILD_BIN="$(resolve_xcodebuild)"
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    DEVELOPER_DIR="$(cd "$(dirname "$XCODEBUILD_BIN")/../.." && pwd)"
    export DEVELOPER_DIR
fi

if [[ "$SKIP_NOTARIZATION" != "1" ]]; then
    [[ -n "$NOTARY_PROFILE" ]] || die "Set NOTARY_PROFILE before running this script."
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST_PATH")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST_PATH")"
RELEASE_NAME="${APP_NAME}-${VERSION}-${BUILD_NUMBER}"

ARCHIVE_PATH="${ARCHIVE_PATH:-$DIST_ROOT/$RELEASE_NAME.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$DIST_ROOT/$RELEASE_NAME}"
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
ZIP_PATH="${ZIP_PATH:-$DIST_ROOT/$RELEASE_NAME.zip}"
DMG_PATH="${DMG_PATH:-$DIST_ROOT/$RELEASE_NAME.dmg}"
NOTARY_RESULT_PATH="${NOTARY_RESULT_PATH:-$DIST_ROOT/$RELEASE_NAME.notary.json}"
NOTARY_LOG_PATH="${NOTARY_LOG_PATH:-$DIST_ROOT/$RELEASE_NAME.notary-log.json}"
SIGNATURE_SUMMARY_PATH="${SIGNATURE_SUMMARY_PATH:-$DIST_ROOT/$RELEASE_NAME.codesign.txt}"
EXPORT_OPTIONS_PLIST="$(mktemp "${TMPDIR:-/tmp}/notchclick-export-options.XXXXXX.plist")"
trap 'rm -f "$EXPORT_OPTIONS_PLIST"' EXIT

mkdir -p "$DIST_ROOT"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
rm -f "$ZIP_PATH" "$DMG_PATH" "$NOTARY_RESULT_PATH" "$NOTARY_LOG_PATH" "$SIGNATURE_SUMMARY_PATH"

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    note "Warning: no local Developer ID Application identity was found in the keychain."
    note "Archive/export may fail until Xcode signing is configured for your Developer ID team."
fi

cat >"$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
EOF

archive_cmd=(
    "$XCODEBUILD_BIN"
    -project "$PROJECT_PATH"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "$DESTINATION"
    -archivePath "$ARCHIVE_PATH"
    DEVELOPMENT_TEAM="$TEAM_ID"
)

export_cmd=(
    "$XCODEBUILD_BIN"
    -exportArchive
    -archivePath "$ARCHIVE_PATH"
    -exportPath "$EXPORT_PATH"
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
)

if [[ "$ALLOW_PROVISIONING_UPDATES" == "1" ]]; then
    archive_cmd+=(-allowProvisioningUpdates)
    export_cmd+=(-allowProvisioningUpdates)
fi

archive_cmd+=(archive)

note "Archiving $APP_NAME $VERSION ($BUILD_NUMBER)"
"${archive_cmd[@]}"

note "Exporting Developer ID build"
"${export_cmd[@]}"

[[ -d "$APP_PATH" ]] || die "Exported app not found at $APP_PATH"

note "Verifying code signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -d --verbose=4 "$APP_PATH" >"$SIGNATURE_SUMMARY_PATH" 2>&1

note "Creating distribution zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "$SKIP_NOTARIZATION" == "1" ]]; then
    note "Skipping notarization because SKIP_NOTARIZATION=1"
    spctl --assess --type execute --verbose=4 "$APP_PATH"
    note "Release artifacts are in $DIST_ROOT"
    exit 0
fi

note "Submitting zip to Apple notarization service"
if ! xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --timeout "$NOTARY_TIMEOUT" \
    --output-format json >"$NOTARY_RESULT_PATH"; then
    cat "$NOTARY_RESULT_PATH" >&2 || true
    die "Notarization failed. Inspect $NOTARY_RESULT_PATH for details."
fi

submission_id="$(plutil -extract id raw -o - "$NOTARY_RESULT_PATH" 2>/dev/null || true)"
if [[ -z "$submission_id" ]]; then
    submission_id="$(plutil -extract submissionId raw -o - "$NOTARY_RESULT_PATH" 2>/dev/null || true)"
fi
if [[ -n "$submission_id" ]]; then
    xcrun notarytool log \
        --keychain-profile "$NOTARY_PROFILE" \
        "$submission_id" \
        "$NOTARY_LOG_PATH" >/dev/null || true
fi

note "Stapling notarization ticket"
xcrun stapler staple -v "$APP_PATH"
xcrun stapler validate -v "$APP_PATH"

note "Rebuilding zip so the stapled ticket is included"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ -x "$PWD/scripts/build_dmg.sh" ]]; then
    note "Building drag-to-Applications DMG"
    "$PWD/scripts/build_dmg.sh" "$APP_PATH" "$DMG_PATH"
fi

note "Running Gatekeeper assessment"
spctl --assess --type execute --verbose=4 "$APP_PATH"

note "Done"
echo "App:            $APP_PATH"
echo "Zip:            $ZIP_PATH"
if [[ -f "$DMG_PATH" ]]; then
    echo "DMG:            $DMG_PATH"
fi
echo "Archive:        $ARCHIVE_PATH"
echo "Signature info: $SIGNATURE_SUMMARY_PATH"
echo "Notary result:  $NOTARY_RESULT_PATH"
if [[ -f "$NOTARY_LOG_PATH" ]]; then
    echo "Notary log:     $NOTARY_LOG_PATH"
fi
