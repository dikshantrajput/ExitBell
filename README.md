# Exit Bell

A minimal macOS menubar app that plays a sound on a timer — giving you a believable excuse to leave any meeting.

No Dock icon. No main window. Just a bell in your menubar.

---

## What's Included

```
ExitBell/
├── ExitBellApp.swift           # App entry point, hides from Dock
├── StatusBarController.swift   # Menubar icon + popover management
├── TimerManager.swift          # Countdown logic (Combine)
├── SoundPlayer.swift           # AVAudioPlayer wrapper
├── PopoverView.swift           # SwiftUI UI
├── Info.plist                  # LSUIElement = YES (no Dock icon)
├── AppIcon.icns                # App icon
├── ExitBell.entitlements
└── Sounds/
    ├── doorbell.aiff
    ├── dog_bark.aiff
    ├── phone_ring.aiff
    └── knock.aiff
```

### Features

- **Timer presets** — 2, 5, or 10 minutes; or pick 1–30 min with a stepper
- **4 sound options** — Doorbell, Dog Bark, Ring, Knock
- **Menubar countdown** — icon switches to a live `4:59` countdown while armed
- **Stop button** — appears while audio is playing, stops it instantly
- **One-tap cancel** — tap the Arm button again to disarm
- **Persisted settings** — last-used duration and sound survive restarts (`@AppStorage`)
- **Launch at login** — toggle in the popover via `SMAppService`

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later
- Apple Developer account (free tier is fine for local/direct distribution)

---

## Installation

### Download

Grab the latest `ExitBell.dmg` from [Releases](../../releases) and drag to Applications.

### Build from source

**1. Clone**
```bash
git clone https://github.com/yourusername/exit-bell.git
cd exit-bell
```

**2. Open in Xcode**
```bash
open ExitBell.xcodeproj
```

**3. Set your Development Team**
1. Select the **ExitBell** target in the project navigator
2. Go to **Signing & Capabilities**
3. Choose your Apple ID team from the **Team** dropdown

**4. Build and run**

Press **⌘R** — the app will launch and a bell icon will appear in your menubar.

---

## Replacing Placeholder Sounds

The bundled `.aiff` files are single-tone placeholders. To use real sounds:

1. Prepare your audio files in `.aiff` format
2. Replace the files in `ExitBell/Sounds/` keeping the exact filenames:
   - `doorbell.aiff`
   - `dog_bark.aiff`
   - `phone_ring.aiff`
   - `knock.aiff`
3. Rebuild — no code changes needed

---

## How It Works

1. Click the menubar bell → popover opens
2. Pick a duration and a sound
3. Click **Arm Timer**
4. The icon switches to a live countdown (`4:59`, `4:58`, …)
5. When the timer fires, the sound plays at full volume
6. A **Stop Sound** button appears — click it to cut the audio

---

## Distribution (DMG)

```bash
brew install create-dmg

create-dmg \
  --volname "Exit Bell" \
  --window-size 540 340 \
  --icon-size 128 \
  --icon "ExitBell.app" 160 160 \
  --app-drop-link 380 160 \
  --volicon "ExitBell.app/Contents/Resources/AppIcon.icns" \
  "ExitBell.dmg" \
  "ExitBell.app"
```

---

## License

MIT — see [LICENSE](LICENSE)
