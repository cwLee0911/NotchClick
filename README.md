<p align="center">
  <a href="https://cwlee0911.github.io/NotchClick/">
    <img src="website/public/app-icon.png" alt="NotchClick app icon" width="112" height="112">
  </a>
</p>

<h1 align="center">NotchClick</h1>

<p align="center">
  A fast, native-feeling launcher and glance panel for the MacBook notch.
</p>

<p align="center">
  <a href="https://cwlee0911.github.io/NotchClick/"><img alt="Download" src="https://img.shields.io/badge/download-NotchClick.dmg-111111?style=for-the-badge"></a>
  <img alt="macOS" src="https://img.shields.io/badge/macOS-13%2B-0A84FF?style=for-the-badge">
  <img alt="Swift" src="https://img.shields.io/badge/SwiftUI-native-FA7343?style=for-the-badge">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-34C759?style=for-the-badge">
</p>

---

## Overview

NotchClick turns the top-center notch area into a compact panel for the things you reach for all day:

| Feature | What it does |
| --- | --- |
| Launcher | Pin favorite apps and open them directly from the notch. |
| Music | Control Apple Music or Spotify without switching context. |
| Menu bar helper | Open the panel, settings, or quit from a small status item. |

The panel appears when you click the notch target, then folds away when you move on.

## Download

Download the latest DMG from the website:

```text
https://cwlee0911.github.io/NotchClick/downloads/NotchClick.dmg
```

Installation is the usual macOS flow:

1. Open `NotchClick.dmg`.
2. Drag `NotchClick.app` into `/Applications`.
3. Launch NotchClick.
4. Approve macOS security prompts when they appear.

## Permissions

NotchClick keeps permissions narrow:

| Permission | Used for |
| --- | --- |
| Apple Events | Controlling Apple Music or Spotify after you choose a player. |
| Launch at login | Optional startup behavior from Settings. |

No Wi-Fi, Bluetooth, or privileged system-control access is requested.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Designed for MacBooks with a notch
- Also works on non-notched Macs by anchoring to the top of the main display

## Build From Source

This project uses XcodeGen to create the Xcode project from `project.yml`.

```bash
./setup.sh
```

Or manually:

```bash
xcodegen generate
open NotchClick.xcodeproj
```

Then select the `NotchClick` scheme and build in Xcode.

## Project Layout

```text
app/NotchClick/              macOS SwiftUI app
app/NotchClick/Modules/      Launcher and Music features
scripts/                     Release and DMG tooling
website/                     Vite website and download page
project.yml                  XcodeGen project definition
```

## Distribution

Direct distribution notes live in [docs/direct-distribution.md](docs/direct-distribution.md).

Public builds should be Developer ID signed, notarized, and packaged as a DMG before updating the website download.
