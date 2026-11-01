# Dev Log: Initial App Architecture, UI, and i18n Implementation

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Context & Motivation
The user requested packaging command-line scripts `~/bin/enable_sleep_macos.sh` (`sudo pmset -a disablesleep 0`) and `~/bin/disable_sleep_macos.sh` (`sudo pmset -a disablesleep 1`) into a native macOS utility application.
Key requirements included:
- Current state display and toggle switch.
- Smart option to automatically disable sleep when plugged into AC power (and restore sleep when on battery).
- Modern macOS aesthetic design (menu bar popover + standalone window).
- Native 5-language internationalization (i18n): English, Simplified Chinese, Traditional Chinese (Taiwan), Traditional Chinese (Hong Kong), and Japanese.
- Passwordless privilege authorization for silent switching.

## 2. Key Milestones Completed
1. **Core Service Engine**:
   - `SleepManager.swift`: Telemetry parser for `pmset -g` (`SleepDisabled`, `displaysleep`, `hibernatemode`), execution wrapper for `disablesleep 1|0`, and one-click `/etc/sudoers.d/mac_sleep_control` setup validated via `/usr/sbin/visudo -cf`.
   - `PowerMonitor.swift`: Event-driven `IOKit.ps` implementation (`IOPSNotificationCreateRunLoopSource`) that eliminates CPU polling loops while detecting AC/Battery power switches in real-time.
   - `AppController.swift`: Observable object coordinating reactive state updates, power transitions, and activity logging.
2. **SwiftUI Modern Aesthetic Interface**:
   - `StatusHeroCard.swift`: Ambient status glow with warm amber (awake) vs. cool indigo (sleep allowed) styling and SF Symbol animations.
   - `MenuBarPopoverView.swift`: Frosted glass menu bar popover for rapid control.
   - `MainWindowView.swift`: Sequoia-style Bento dashboard featuring smart power automation, security privileges, live telemetry, and recent logs.
3. **i18n Localization Engine**:
   - Implemented `I18n.swift` with `.lproj/Localizable.strings` dictionaries across `en`, `zh-Hans`, `zh-Hant-TW`, `zh-Hant-HK`, `ja`.
   - Added instant runtime language switching dropdown.
4. **App Packaging & Icon Generation**:
   - `scripts/generate_icon.swift`: CoreGraphics squircle generator creating 10-resolution iconset and `.icns`.
   - `build_app.sh`: Automated release build, resource copy, plist generation, and ad-hoc codesigning.

## 3. Verification & Results
- Built release binary and bundled `SleepControl.app`.
- Process verified active via `pgrep -fl SleepControl`.
- Verified status reading matches `pmset -g` output.
- All code comments and documentation normalized to English.
