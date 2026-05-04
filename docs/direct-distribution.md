# Direct Distribution

This project is set up for direct macOS distribution with Developer ID signing and notarization.

The Xcode project, primary target, app name, and bundle IDs are all aligned as `NotchClick` / `com.notchclick.*`.

## One-time setup

1. In Xcode, open `NotchClick.xcodeproj`.
2. Select the `NotchClick` target.
3. In Signing & Capabilities, choose your Apple Developer team.
4. Make sure your Mac has a `Developer ID Application` certificate available.
5. Create a notarytool keychain profile:

```bash
xcrun notarytool store-credentials NotchClick-Notary \
  --apple-id "you@example.com" \
  --team-id "ABCDE12345"
```

`notarytool` prompts for your app-specific password securely if you omit `--password`.

## Build and notarize

Run the release script from the project root:

```bash
TEAM_ID="ABCDE12345" \
NOTARY_PROFILE="NotchClick-Notary" \
./scripts/release_direct.sh
```

If Xcode needs to talk to Apple to refresh signing assets, add:

```bash
ALLOW_PROVISIONING_UPDATES=1
```

If you want to test archive/export without notarization, add:

```bash
SKIP_NOTARIZATION=1
```

## Output

The script writes release artifacts into `dist/`:

- `NotchClick-<version>-<build>/NotchClick.app`
- `NotchClick-<version>-<build>.zip`
- `NotchClick-<version>-<build>.dmg`
- `NotchClick-<version>-<build>.xcarchive`
- `NotchClick-<version>-<build>.codesign.txt`
- `NotchClick-<version>-<build>.notary.json`
- `NotchClick-<version>-<build>.notary-log.json` when a submission ID is available

The generated DMG includes an `Applications` shortcut and a Finder layout that
visually tells people to drag `NotchClick.app` into `Applications` before
ejecting the disk image.

## Verification

The script already runs these checks for you:

- `codesign --verify --deep --strict`
- `xcrun stapler validate`
- `spctl --assess --type execute --verbose=4`

After a successful notarized build, `spctl` should report an accepted result, ideally with `source=Notarized Developer ID`.

## Troubleshooting

- If archive or export fails, open Xcode once and confirm your team is selected for the target.
- If notarization fails, inspect the `*.notary.json` and `*.notary-log.json` files in `dist/`.
- If Gatekeeper does not accept the app, rerun the script and make sure the final zip was recreated after stapling.
