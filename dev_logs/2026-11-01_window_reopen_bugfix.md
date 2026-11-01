# Dev Log: Fix Main Window Reopen After Closing via Red 'x' Button

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Bug Report & Root Cause Analysis
- **Symptom**: After clicking the top-left close (`x`) button on the main dashboard window, clicking the application icon in the macOS Dock or double-clicking `SleepControl.app` in Finder failed to re-summon the main dashboard window.
- **Root Causes Identified**:
  1. **Missing `applicationShouldHandleReopen(_:hasVisibleWindows:)` in `AppDelegate`**: When a user clicks the Dock icon of a running macOS application or double-clicks its `.app` bundle in Finder, AppKit dispatches `kAEReopenApplication` (`applicationShouldHandleReopen`). Without implementing this delegate method and managing a persistent window reference, the closed window remained hidden.
  2. **`NSStatusBarWindow` Interference with `hasVisibleWindows` Flag**: Because the application hosts a menu bar `NSStatusItem`, AppKit maintains an internal `NSStatusBarWindow` that is always considered visible (`hasVisibleWindows == true`). Relying on `!flag` or SwiftUI's automatic `Window` scene restoration caused reopen events to be ignored.
  3. **SwiftUI `Window` Scene Lifecycle**: Using SwiftUI's declarative `Window` scene alongside `NSApplicationDelegate` caused state restoration conflicts and prevented deterministic `makeKeyAndOrderFront` behavior after closing.

## 2. Technical Solution Implemented
1. **Pure AppKit `@main` Lifecycle (`SleepControlApp.swift`)**:
   - Promoted `AppDelegate` to `@main` entry point (`static func main()`), eliminating duplicate or stale restored SwiftUI windows.
   - Implemented `applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool` to unconditionally invoke `StatusItemManager.shared.showMainWindow()`.
   - Configured standard macOS Main Menu (`⌘0` to summon Dashboard, `⌘W` to close window, `⌘M` to minimize, `⌘Q` to quit).
2. **Managed `NSWindow` with `isReleasedWhenClosed = false` (`StatusItemManager.swift`)**:
   - `StatusItemManager` directly instantiates and retains `mainWindow: NSWindow?` hosting `MainWindowView`.
   - Set `window.isReleasedWhenClosed = false` and `window.isRestorable = false` so clicking the red `x` button cleanly hides the window without deallocating it, allowing instant re-display via Dock click, Finder double-click, or Menu Bar Popover action.

## 3. Verification
- Rebuilt `SleepControl.app` via `./build_app.sh`.
- Verified via `CGWindowListCopyWindowInfo` that exactly 1 Layer-0 window (`800 x 690`) is presented on launch and cleanly re-summoned upon reopen events.
