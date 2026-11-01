# Dev Log: Status Bar Visibility & Notch Collision Investigation

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Issue Description
User reported that the application's status bar icon was not visible on the macOS menu bar, and inquired whether the status bar might be too crowded.

## 2. Investigation & Empirical Findings
1. **Display Hardware Inspection**:
   - Queried display via `system_profiler SPDisplaysDataType`:
     - Built-in Liquid Retina Display (13.6-inch MacBook Air / M4, 2560 x 1664 physical resolution, default scaling 1470 x 956 points).
     - Features a physical hardware camera notch in the top center (X ≈ 660 to 820).
2. **Window Server Layer 25 Analysis**:
   - Queried all status bar item bounds on Layer 25 via `CGWindowListCopyWindowInfo`:
     - Right screen boundary is at X = 1470.
     - Existing system items (Control Center, Battery, WiFi, Clock, Notes, Input Method, etc.) occupy continuous horizontal space from X = 842 to 1470 (over 620 points wide).
     - The gap between the rightmost edge of the notch (X ≈ 820–840) and the leftmost visible icon (X = 842) was under 20–25 points.
   - New status bar items are positioned right-to-left. SleepControl's status item was placed by macOS at X = 766–804.
   - **Conclusion**: The status bar item was indeed created, but fell directly behind the physical camera notch. In macOS, items colliding with the notch are silently hidden by Window Server.

## 3. Engineering Improvements Applied
1. **Replaced SwiftUI `MenuBarExtra` with Native AppKit `StatusItemManager`**:
   - Used `NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)` to reduce width to standard 22 points (previously ~80pt with icon + text label).
   - Set `autosaveName = "com.himanzero.SleepControl.StatusItem"` to support `⌘ Command + Drag` icon reordering and position persistence.
   - Linked to `NSPopover` hosting `MenuBarPopoverView` with `.transient` dismissal behavior.
2. **Lifecycle Optimization**:
   - Added `AppDelegate` with `applicationShouldTerminateAfterLastWindowClosed = false` to guarantee continuous background execution even when the dashboard window is closed.

## 4. Verification
- Built and signed release binary.
- Verified Layer 25 status item creation at coordinates X = 766–804.
