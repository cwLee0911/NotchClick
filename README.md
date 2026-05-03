# NotchClick [DOWNLOAD PAGE](https://cwlee0911.github.io/NotchClick/).

**Your MacBook notch, now useful.**

NotchClick turns your MacBook's notch into a fast, native-feeling control panel.

Click the notch once to access your favorite apps, music controls, system status,
and quick Mac settings -- all from one compact space at the top
of your screen.

Move your cursor away, and it quietly folds back into the notch.
---

## What you can do

- **Open apps faster**  
  Pin your favorite apps and launch them directly from the notch.

- **Control your music**  
  See what's playing and control Apple Music or Spotify.

- **Monitor your Mac**  
  See CPU, memory, storage, battery, and system status at a glance.

- **Switch language quickly**  
  Access language controls without opening macOS settings.

- **Toggle Low Power Mode**  
  Turn Low Power Mode on or off from the System panel.

---

## System Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Designed for MacBooks with a notch  
  Also works on non-notched Macs by anchoring to the top of the main display.

---

## Install

1. Download the latest `NotchClick.dmg` from the
   [website](https://cwlee0911.github.io/NotchClick/).
2. Open the DMG.
3. Drag **NotchClick.app** into your `/Applications` folder.
4. Eject the DMG.
5. Open **NotchClick** from `/Applications`.

On first launch, macOS may show a security dialog.  
The app inside the DMG is notarized by Apple, so you can safely click **Open**.

Direct download:

```text
https://cwlee0911.github.io/NotchClick/downloads/NotchClick.dmg
```

---

## Low Power Mode permission

The first time you toggle Low Power Mode, macOS asks for your administrator
password.

NotchClick uses this once to allow only these exact system commands:

```bash
/usr/bin/pmset -a lowpowermode 0
/usr/bin/pmset -a lowpowermode 1
```
