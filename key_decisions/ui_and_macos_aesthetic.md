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

## Decision 4: Screen-Boundary-Adaptive Resizable `StatusBarPanel` (`NSPanel`) over `NSPopover`
- **Status**: Accepted (Supersedes `NSPopover`)
- **Context**: When the status bar item was positioned close to the right edge of the screen, `NSPopover` with `NSHostingController` failed to clamp its expanded width to the screen's right boundary, causing the right portion of the popover to be clipped off-screen. Furthermore, `_NSPopoverWindow` locked the window frame so users could neither drag nor resize the popup.
- **Decision Outcome**:
  - Replace `NSPopover` with a custom `StatusBarPanel` (`NSPanel` subclass) styled with `NSVisualEffectView` (`.popover` material, `16pt` continuous corner radius) matching macOS Sonoma/Sequoia Control Center panels.
  - Override `constrainFrameRect(_:to:)` and explicitly clamp `(origin.x, origin.y)` within `screen.visibleFrame.insetBy(dx: 10, dy: 10)` when opening below the `NSStatusBarButton`.
  - Enable `.resizable` (`minWidth: 350, maxWidth: 540`) and `isMovableByWindowBackground = true` so the user can freely resize or reposition the panel if desired.
  - Maintain transient auto-dismiss behavior when clicking outside or resigning key status.

## Decision 5: Emotional Companion Stage & Multi-Layer Aurora Aesthetic
- **Status**: Accepted
- **Context**: A purely utilitarian Bento dashboard feels static and lacks emotional resonance. Since `SleepControl` already features an adorable cat mascot (`status_cat_awake` / `status_cat_sleeping`), elevating the cat into an interactive, living desktop companion significantly increases emotional value without sacrificing technical clarity.
- **Decision Outcome**:
  - **High-Res Full-Detail Companion Artwork**: Extracted `hero_cat_awake` and `hero_cat_sleeping` (`@1x` and `@2x` full-detail PNGs with smooth un-premultiplied white alpha edges) from the original artwork so the hero stage preserves the cat's inner ears, whiskers, pupils, nose, and 3D fur shading.
  - **Living Micro-Animations via `TimelineView`**: Used `TimelineView(.animation)` sine-wave modulation to drive continuous breathing scale/elevation, outer halo pulsing, floating `"z Z"` sleep particles + twinkling stars when sleep is allowed, and golden sparkles when keeping the Mac awake.
  - **Interactive Petting & Companion Speech Bubble**: Clicking the cat stage or the companion speech bubble triggers `AppController.petCompanion()`, bouncing the cat with a spring animation, popping a floating heart badge, and cycling localized 1st-person companion quotes across all 5 supported languages.
  - **Multi-Layer Aurora Ambient Backdrop**: Added `AuroraAmbientBackdrop` with drifting radial color orbs (warm golden-coral sunrise when awake; midnight indigo-violet nebula when sleeping) to both `MainWindowView` and `MenuBarPopoverView`.

## Decision 6: Dashboard Version Display Hierarchy & In-Flow Footer Placement
- **Status**: Accepted
- **Context**: Users and testers need a clear visual indicator of the installed application version to verify updates and report issues. The indicator must sit in the empty bottom-left region of the dashboard without competing with primary action controls or obscuring Bento cards when the window is resized.
- **Decision Outcome**:
  - **In-Flow Footer Placement**: Placed `dashboardFooterSection` as the terminal child in `ScrollView > VStack` rather than an absolute overlay or floating safe-area inset. This ensures that when the window is resized to minimum dimensions (`minHeight: 750`), content scrolls naturally without cards slipping behind a floating label.
  - **Tertiary Typography Scale**: Styled with `.system(size: 11, weight: .regular, design: .monospaced)` and `.foregroundStyle(.tertiary)`, aligning with low-level command metadata and timeline timestamps.
  - **Non-Interactive & Window Drag Pass-Through**: Applied `.allowsHitTesting(false)` so clicks and drags pass through to the underlying window background (`window.isMovableByWindowBackground = true`), preventing accidental text selection or drag interruptions.
  - **Multi-Tiered Version Resolution**: Created `AppVersion` service resolving `CFBundleShortVersionString` dynamically from the main bundle, falling back to local dev bundle inspection, and finally to a static release fallback.
  - **Universal i18n Format**: Added `"dashboard.version" = "v%@";` across all 5 supported `.lproj` catalogs.
