# Key Decisions: UI Form Factor & macOS Aesthetic Design

## Decision 1: Dual-Form (Menu Bar Popover + Standalone Bento Dashboard)
- **Status**: Accepted
- **Context**: Users need quick toggling and glanceable state in daily use, as well as an in-depth dashboard for reviewing automation rules, telemetry parameters, and security settings.
- **Options Considered**:
  1. *Menu bar item only*: Minimal screen footprint, but insufficient space for telemetry details, multi-language configuration, and activity logs.
  2. *Dock window only*: Full desktop dashboard space, but inconvenient for quick glance or momentary toggle.
  3. *Dual-Form Architecture*: Best of both worlds. `NSStatusItem` + `NSPopover` provides an instant frosted-glass popover; the standalone Sequoia Bento-style window provides full configuration and telemetry.
- **Decision Outcome**: Adopted option 3. Created `MenuBarPopoverView.swift` and `MainWindowView.swift` sharing `AppController.shared`.

## Decision 2: Pure AppKit Window Management (`NSWindow` + `NSHostingController`) over SwiftUI `Window` Scene
- **Status**: Accepted (Supersedes initial SwiftUI `Window` scene)
- **Context**: In a hybrid Dock + Status Bar app, closing the main window via the red `x` button and subsequently clicking the Dock icon or double-clicking `SleepControl.app` in Finder failed to reopen the window under SwiftUI's `Window` scene lifecycle (partially because `NSStatusItem`'s `NSStatusBarWindow` causes macOS to report `hasVisibleWindows = true`).
- **Decision Outcome**:
  - Use `@main final class AppDelegate: NSObject, NSApplicationDelegate` as the explicit lifecycle owner.
  - Manage the dashboard `NSWindow` inside `StatusItemManager` with `isReleasedWhenClosed = false`.
  - Unconditionally call `StatusItemManager.shared.showMainWindow()` inside `applicationShouldHandleReopen(_:hasVisibleWindows:)`.
- **Consequences**: 100% deterministic window reopen behavior from Dock clicks, Finder double-clicks, `⌘0` shortcut, and Menu Bar popover button, with zero ghost/restored windows.
