# Dev Log: Screen-Boundary-Adaptive & Resizable Status Bar Control Panel

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Context & Motivation
When the status bar icon was located near the right edge of the display, clicking it caused the `NSPopover` control window to overflow past the right screen boundary and appear partially clipped. In addition, `NSPopover` locked its window geometry, preventing the user from moving or resizing the popup window.

## 2. Technical Changes
1. **Replaced `NSPopover` with `StatusBarPanel` (`NSPanel` Subclass)** ([`StatusItemManager.swift`](file:///Users/himanzero/Documents/gitRepo/app-mac-sleep-control/Sources/SleepControl/Services/StatusItemManager.swift)):
   - Implemented `StatusBarPanel` overriding `constrainFrameRect(_:to:)` to guarantee the panel frame never exceeds `screen.visibleFrame.insetBy(dx: 8, dy: 8)`.
   - Calculated exact screen coordinates of the `NSStatusBarButton` in `showStatusPanel(relativeTo:)` and clamped `origin.x` to `[visibleFrame.minX + 10, visibleFrame.maxX - panelWidth - 10]`, ensuring 100% visibility even when the status bar icon is at the far right edge of the screen.
   - Enabled `.resizable` (`minSize: 350x300`, `maxSize: 540x560`) and `isMovableByWindowBackground = true`, allowing the user to freely adjust the width/size or drag the panel.
   - Preserved transient auto-close behavior via `windowDidResignKey(_:)` and a global outside mouse-down monitor.
2. **Flexible Width Layout in [`MenuBarPopoverView.swift`](file:///Users/himanzero/Documents/gitRepo/app-mac-sleep-control/Sources/SleepControl/Views/MenuBarPopoverView.swift)**:
   - Replaced fixed `.frame(width: 420)` with `.frame(minWidth: 350, idealWidth: 400, maxWidth: 540)` so all internal cards and header items adapt smoothly when resized.

## 3. Verification
- Compiled and launched `SleepControl.app` via `./build_app.sh`.
- Verified that clicking the status bar icon near the right screen boundary automatically shifts the control panel leftwards with a clean 10pt margin from the screen edge, and supports edge-dragging to resize and background-dragging to reposition.
