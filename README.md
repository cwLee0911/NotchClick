# NotchClick

**Turn the MacBook notch into a fast native control panel.**

[Website](https://cwlee0911.github.io/NotchClick/) |
[Releases](https://github.com/cwLee0911/NotchClick/releases) |
[Distribution notes](docs/direct-distribution.md)

> Release build is being prepared. The Releases page is linked now, and the
> signed DMG will be published there when it is ready.

---

## Preview

NotchClick opens from the top-center notch area and folds into a compact panel
for the things you reach for most: apps, music, weather, Bluetooth, language,
and live system status.

## Highlights

- **Notch launcher** - pin favorite apps and open them from the expanded notch.
- **Music controls** - choose Apple Music or Spotify, then control playback in place.
- **Local weather** - show current conditions using your location only for weather.
- **Control center** - switch language, manage paired Bluetooth devices, and choose a music app.
- **System monitor** - glance at CPU, memory, storage, battery, and Low Power Mode.
- **Native macOS feel** - lightweight SwiftUI app with a menu-bar-style presence.

## Release Status

NotchClick is not published as a public DMG yet.

When the first build is ready, it will appear here:

```text
https://github.com/cwLee0911/NotchClick/releases
```

Planned install flow:

1. Download the latest `NotchClick.dmg` from the Releases page.
2. Open the DMG.
3. Drag `NotchClick.app` into `/Applications`.
4. Open NotchClick from `/Applications`.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Designed for notched MacBooks
- Also works on non-notched Macs by anchoring to the top of the main display

## Repository Layout

```text
app/       macOS app source, helper tool, and app icon assets
website/   marketing website source
scripts/   release and packaging scripts
docs/      direct distribution notes
```

## Privacy Notes

- Location is requested only for local weather.
- Music automation is used only after selecting Apple Music or Spotify.
- Bluetooth access is used to show and manage paired devices where macOS allows it.
- Low Power Mode setup is limited to the exact `pmset` commands needed to toggle the setting.

## Low Power Mode Permission

The first Low Power Mode setup may require administrator approval. NotchClick
limits passwordless access to these exact commands:

```bash
/usr/bin/pmset -a lowpowermode 0
/usr/bin/pmset -a lowpowermode 1
```

## Development

Generate the Xcode project from `project.yml`, then build the macOS app in Xcode.

```bash
xcodegen generate
```

Run the website locally:

```bash
cd website
npm install
npm run dev
```

## License

MIT
