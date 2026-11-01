# SleepControl — macOS Power & Sleep Management Utility

`SleepControl.app` is a modern native macOS application built with **Swift + SwiftUI + IOKit**. It wraps `sudo pmset -a disablesleep 1` (prevent system sleep and clamshell sleep) and `sudo pmset -a disablesleep 0` (restore system sleep) into a lightweight desktop utility featuring both a **Menu Bar Popover** and a standalone **Bento-style Dashboard Window**.

---

## Key Features

1. **One-Click Toggle & Real-Time Status Synchronization**
   - Live telemetry monitoring of `SleepDisabled` via `/usr/bin/pmset -g`, display sleep timer, system sleep mode, and battery status.
   - Seamless toggling between sleep allowed and sleep disabled from either the **Menu Bar Popover** or the **Main Dashboard Window**.
   - External changes (such as running CLI scripts like `~/bin/enable_sleep_macos.sh` or `~/bin/disable_sleep_macos.sh`) are automatically detected and reflected in the UI.

2. **Automatic Disable Sleep on AC Power (Zero-Polling Hardware Events)**
   - Monitors AC/Battery power transition events in real time using macOS `IOKit.ps` (`IOPSNotificationCreateRunLoopSource`) with zero background CPU polling overhead.
   - When **"Auto Disable Sleep on AC"** is enabled:
     - **Connected to AC Power**: Automatically executes `sudo pmset -a disablesleep 1` (keeps Mac awake even when the lid is closed).
     - **Switched to Battery Power**: Automatically restores `sudo pmset -a disablesleep 0` (restores default energy conservation).

3. **One-Click Passwordless Sudo Authorization (Safe `visudo` Verification)**
   - Built-in one-click setup to configure passwordless execution for `/usr/bin/pmset`.
   - Requires administrator authentication only once via macOS native Touch ID / Password prompt. It safely writes to `/etc/sudoers.d/mac_sleep_control` (permissions `0440`) after strict syntax verification using `/usr/sbin/visudo -cf`.
   - Once configured, all manual toggles and automatic power-event triggers execute silently within milliseconds without password prompts. Can be revoked at any time.

4. **Multi-Language Support (i18n)**
   - Fully localized in 5 languages:
     - **English (`en`)** (Default fallback language)
     - **Simplified Chinese (`zh-Hans`)**
     - **Traditional Chinese - Taiwan (`zh-Hant-TW`)**
     - **Traditional Chinese - Hong Kong (`zh-Hant-HK`)**
     - **Japanese (`ja`)**
   - Automatically matches the system preferred language, falling back to English if unsupported.
   - Supports instant runtime language switching from the menu bar or dashboard without requiring an application restart.

---

## Building and Running

To build the release application bundle:

```zsh
./build_app.sh
```

Upon completion, `SleepControl.app` will be created in the project root directory. You can launch it directly or copy it to `/Applications`:

```zsh
# Launch directly
open SleepControl.app

# Install to Applications folder
cp -R SleepControl.app /Applications/
```
