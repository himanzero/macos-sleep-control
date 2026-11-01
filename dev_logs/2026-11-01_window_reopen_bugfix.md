# Dev Log: Fix Main Window Reopen & Dynamic Dock Icon Visibility (`regular` <-> `accessory`)

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Context & Requirements
1. **Reopen Reliability**: Clicking the top-left close (`x`) button on the main dashboard window and subsequently re-launching `SleepControl.app` in Finder or clicking "Open Dashboard" in the status bar popover must reliably re-summon the main window.
2. **Dynamic Dock Visibility**: When the user closes the main dashboard window via the top-left `x` button (or `⌘W`), the application should continue running in the background (with status bar item and `IOKit` power monitoring active) while **hiding its icon from the macOS Dock** (`NSApplication.ActivationPolicy.accessory`). When the main window is opened again, the Dock icon should be restored (`NSApplication.ActivationPolicy.regular`).

## 2. Technical Solution Implemented
1. **Pure AppKit `@main` Lifecycle (`SleepControlApp.swift`)**:
   - Promoted `AppDelegate` to `@main` entry point (`static func main()`), eliminating duplicate or stale restored SwiftUI windows.
   - Implemented `applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool` to unconditionally invoke `StatusItemManager.shared.showMainWindow()`.
2. **Managed `NSWindow` & Dynamic Activation Policy (`StatusItemManager.swift`)**:
   - `StatusItemManager` conforms to `NSWindowDelegate` and assigns `window.delegate = self` on `mainWindow`.
   - Set `window.isReleasedWhenClosed = false` and `window.isRestorable = false`.
   - In `showMainWindow()`: sets `NSApp.setActivationPolicy(.regular)` so the Dock icon and application menu appear whenever the dashboard window is presented.
   - In `windowWillClose(_ notification: Notification)`: asynchronously switches `NSApp.setActivationPolicy(.accessory)`, immediately removing the icon from the Dock once the dashboard window closes while keeping the background process and status bar icon alive.

## 3. Verification
- Rebuilt `SleepControl.app` via `./build_app.sh` and verified clean launch (`PID 74098`).
