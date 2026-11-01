# Key Decisions: UI Form Factor & macOS Aesthetic Design

## Decision 1: Dual-Form (Menu Bar Popover + Standalone Bento Dashboard)
- **Status**: Accepted
- **Context**: Users need quick toggling and glanceable state in daily use, as well as an in-depth dashboard for reviewing automation rules, telemetry parameters, and security settings.
- **Decision Outcome**: Adopted Dual-Form Architecture (`NSStatusItem` + `NSPopover` for instant menu bar access, plus a standalone Sequoia Bento-style dashboard window).

## Decision 2: Pure AppKit Window Management (`NSWindow` + `NSHostingController`) over SwiftUI `Window` Scene
- **Status**: Accepted (Supersedes initial SwiftUI `Window` scene)
- **Context**: In a hybrid Dock + Status Bar app, closing the main window via the red `x` button and subsequently re-opening `SleepControl.app` failed to reopen the window under SwiftUI's `Window` scene lifecycle.
- **Decision Outcome**:
  - Use `@main final class AppDelegate: NSObject, NSApplicationDelegate` as the explicit lifecycle owner.
  - Manage the dashboard `NSWindow` inside `StatusItemManager` with `isReleasedWhenClosed = false`.
  - Unconditionally call `StatusItemManager.shared.showMainWindow()` inside `applicationShouldHandleReopen(_:hasVisibleWindows:)`.

## Decision 3: Dynamic Activation Policy Switching (`.regular` when Window Open, `.accessory` when Window Closed)
- **Status**: Accepted
- **Context**: When the user closes the main dashboard window via the top-left `x` button, the app stays running in the background to monitor AC/Battery transitions and serve the menu bar item, but keeping an inactive icon in the Dock clutters the user's Dock.
- **Decision Outcome**:
  - Call `NSApp.setActivationPolicy(.regular)` inside `StatusItemManager.showMainWindow()` so the Dock icon is shown while the dashboard window is open.
  - Implement `NSWindowDelegate.windowWillClose(_:)` on `StatusItemManager` to call `NSApp.setActivationPolicy(.accessory)` when the dashboard window closes, hiding the Dock icon while preserving background execution.
- **Consequences**: Clean, uncluttered Dock when running in the background; full Dock & window presence when the dashboard is open; re-opening via Menu Bar Popover or double-clicking `SleepControl.app` in Finder seamlessly restores both the window and the Dock icon.
