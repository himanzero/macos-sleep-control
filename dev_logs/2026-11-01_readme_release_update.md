# Dev Log: README Update After First GitHub Release

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Context & Motivation
After publishing the first GitHub Release, the README needed to point end users to the prebuilt binary and fix stale references to improve discoverability.

## 2. Changes (`README.md`)
1. Fixed the clone URL and directory name to the actual repository `himanzero/macos-sleep-control`.
2. Added Release and Downloads badges.
3. Added a search-friendly tagline ("Keep your Mac awake with the lid closed... alternative to Amphetamine / Caffeine").
4. Added a **Download & Installation** section: Releases link, Gatekeeper workaround for the ad-hoc signed app, requirements, first-time passwordless setup, and uninstall steps.
5. Renamed the build section to "Building from Source" and added a **Contributing** section.

## 3. Verification
- Confirmed the sudoers path `/etc/sudoers.d/mac_sleep_control` and the in-app Revoke action exist in the source (`SleepManager.swift`, `AppController.swift`).
