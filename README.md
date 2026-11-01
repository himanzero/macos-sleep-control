# SleepControl — macOS Power & Sleep Management Utility

[![Release](https://img.shields.io/github/v/release/himanzero/macos-sleep-control)](https://github.com/himanzero/macos-sleep-control/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/himanzero/macos-sleep-control/total)](https://github.com/himanzero/macos-sleep-control/releases)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Language](https://img.shields.io/badge/Swift-5.10%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)]()

![SleepControl App Icon](docs/assets/app_icon.png)

**Keep your Mac awake with the lid closed.** A lightweight alternative to Amphetamine / Caffeine, built on `pmset disablesleep`.

`SleepControl.app` is a modern native macOS utility built with **Swift + SwiftUI + AppKit + IOKit**. It seamlessly bridges `sudo pmset -a disablesleep 1` (preventing system and clamshell sleep) and `sudo pmset -a disablesleep 0` (restoring default energy conservation) into an elegant, lightweight desktop app.

---

## 📸 Screenshots

### Bento Control Dashboard
| English (`en`) | Simplified Chinese (`zh-Hans`) |
| :---: | :---: |
| ![SleepControl Dashboard (English)](docs/assets/dashboard_en.png) | ![SleepControl Dashboard (Simplified Chinese)](docs/assets/dashboard_zh.png) |

### Menu Bar Quick Popover
| English (`en`) | Simplified Chinese (`zh-Hans`) |
| :---: | :---: |
| ![Menu Bar Popover (English)](docs/assets/menubar_popover_en.png) | ![Menu Bar Popover (Simplified Chinese)](docs/assets/menubar_popover_zh.png) |

---

## ✨ Key Features

1. **One-Click Toggle & Real-Time Status Synchronization**
   - Live telemetry monitoring of `SleepDisabled` via `/usr/bin/pmset -g`, display sleep timer, system sleep mode, and battery status.
   - Seamless toggling between sleep allowed and sleep disabled from either the **Menu Bar Popover** or the standalone **Bento Dashboard Window**.
   - External CLI changes (e.g., executing `pmset` in Terminal) are automatically synchronized in real time.

2. **Smart AC Power Automation (Zero-Polling Hardware Events)**
   - Monitors AC/Battery power transition events in real time using macOS `IOKit.ps` (`IOPSNotificationCreateRunLoopSource`) with **zero CPU polling overhead**.
   - When **"Auto Disable Sleep on AC"** is enabled:
     - **Connected to AC Power**: Automatically executes `sudo pmset -a disablesleep 1` (keeps Mac awake even when the lid is closed).
     - **Switched to Battery Power**: Automatically restores `sudo pmset -a disablesleep 0` (preserves battery life).

3. **One-Click Passwordless Sudo Authorization (Safe `visudo` Verification)**
   - Built-in one-click setup to configure passwordless execution exclusively for `/usr/bin/pmset`.
   - Requires administrator authentication only once via macOS native Touch ID / Password prompt.
   - Safely verified using `/usr/sbin/visudo -cf` before writing to `/etc/sudoers.d/mac_sleep_control` (permissions `0440`).
   - All subsequent toggles and power-event triggers execute silently in milliseconds without intrusive password dialogs. Can be revoked at any time.

4. **Multi-Language Support (i18n)**
   - Fully localized across 5 languages:
     - **English (`en`)** (Default fallback)
     - **Simplified Chinese (`zh-Hans`)**
     - **Traditional Chinese - Taiwan (`zh-Hant-TW`)**
     - **Traditional Chinese - Hong Kong (`zh-Hant-HK`)**
     - **Japanese (`ja`)**
   - Supports instant runtime language switching from the menu bar or dashboard without requiring an application restart.

5. **Clean Dock & Menu Bar Integration**
   - Compact 22pt status bar icon with `⌘ Command + Drag` position reordering.
   - Automatically hides from the Dock (`.accessory` activation policy) when the main dashboard is closed, maintaining a clutter-free workspace while running silently in the background.
   - Re-summon the dashboard anytime via the Menu Bar Popover, Dock click, or Finder.

---

## 📥 Download & Installation

1. Download the latest `SleepControl-*.zip` from the [**Releases page**](https://github.com/himanzero/macos-sleep-control/releases/latest).
2. Unzip it and drag `SleepControl.app` into your `/Applications` folder.
3. **First launch (Gatekeeper)**: the app is ad-hoc signed (not notarized), so macOS may block it on first launch. Either:
   - Right-click `SleepControl.app` → **Open** → **Open**, or
   - Run in Terminal:
     ```zsh
     xattr -dr com.apple.quarantine /Applications/SleepControl.app
     ```

**Requirements**: macOS 14.0 (Sonoma) or later, Apple Silicon or Intel.

### First-Time Setup
On first use, click **Configure** in the app to enable passwordless `sudo` for `/usr/bin/pmset` (one-time Touch ID / password prompt). After that, all toggles and AC automation run silently.

### Uninstall
1. In the app, click **Revoke** to remove the passwordless authorization (or manually delete `/etc/sudoers.d/mac_sleep_control`).
2. Quit the app and delete `SleepControl.app`.

---

## 🛠 Building from Source

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ or Swift 5.10+ command line tools

### Build & Package Bundle
Clone the repository and run the automated build script:

```zsh
git clone https://github.com/himanzero/macos-sleep-control.git
cd macos-sleep-control
./build_app.sh
```

The script compiles the release binary, creates the iconset, packages the `.app` bundle with all localization `.lproj` directories, and applies an ad-hoc codesign signature.

```zsh
# Launch the app directly
open SleepControl.app

# Or copy to Applications
cp -R SleepControl.app /Applications/
```

---

## 🔒 Security & Privacy

`SleepControl` is completely open-source and respects your system integrity:
- **No Network Telemetry**: Zero data collection, tracking, or network requests.
- **Scoped Privilege Boundary**: Passwordless sudoers configuration is strictly scoped to `/usr/bin/pmset` with read/write protections and syntax validation.
- **Safe Sandboxing of Settings**: Preferences are stored locally in standard `UserDefaults`.

---

## 🤝 Contributing

Issues and pull requests are welcome! Please open an [issue](https://github.com/himanzero/macos-sleep-control/issues) to report bugs or suggest features.

---

## 📄 License

This project is open-source software licensed under the [MIT License](LICENSE).
