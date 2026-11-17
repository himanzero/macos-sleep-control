# Dev Log: Dopamine Micro-Interactions & Tactile Feedback (v2.1.0)

- **Timestamp**: 2026-11-17T13:10:00+08:00
- **Author / Agent**: Antigravity

## 1. Context & Motivation
Building on the v2.0.0 Haute Couture Editorial UI overhaul, SleepControl v2.1.0 introduces "Quiet Luxury" dopamine micro-interactions and Force Touch / trackpad tactile feedback across the main magazine cover, menu bar panel, and diagnostic Bento drawer. The goal is to make every hover, sweep, click, and state transition feel physically responsive and rewarding without sacrificing editorial restraint or CLT/SwiftPM compatibility.

## 2. Technical & Design Decisions Made
- **Centralized Haptic Feedback (`HapticEngine.swift`)**:
  - Created `HapticEngine` wrapping `NSHapticFeedbackManager.defaultPerformer` with four semantic channels: `caress()` (`.generic`, rate-limited with an `NSLock`-guarded 0.5s cooldown), `tap()` (`.generic`), `snap()` (`.alignment`), and `toggle()` (`.levelChange`).
- **Reusable Editorial Motion Primitives (`EditorialTheme.swift`)**:
  - Extended `EditorialInteractionState` (`ObservableObject`) with `parallaxPoint`, `catTilt`, `sheenTrigger`, `irisOrigin`, `irisProgress`, and `haloPulseTrigger`.
  - Added `CircularIrisShape` (animatable `Shape` expanding from an arbitrary `UnitPoint` origin), `SpecularSheenOverlay` (45-degree silk sheen sweep), and `LiquidIndicatorDot` (spring pop-in + expanding ripple halo).
  - Used `ObservableObject` + `@StateObject` for view-local animation state (`SpecularSheenOverlayState`, `LiquidIndicatorDotState`, `MainWindowMotionState`, `MenuBarPopoverMotionState`, `NerdDashboardRevealState`) to avoid `SwiftUIMacros` `@State` compilation failures under Command Line Tools / SwiftPM.
- **Main Magazine Cover Interactions (`MainWindowView.swift`)**:
  - Single-click cat/pill toggle triggers `HapticEngine.toggle()`, a 0.42s `CircularIrisShape` theme reveal from the click/hover origin, choreographed vertical/opacity headline and subtitle rolling transitions, cat squash-and-rebound (`spring(response: 0.34, dampingFraction: 0.60)`), and an expanding amber/ivory halo ring pulse.
  - Added 3-layer depth 3D cover parallax (`±2.5°` `rotation3DEffect` + layered offsets) via `onContinuousHover`.
  - Added zero-press hover petting over the centerpiece cat: cursor-following `catTilt` plus brisk-stroke detection that triggers `HapticEngine.caress()`, `SpecularSheenOverlay`, ear-perk bounce, and a floating `✦` sparkle without toggling `pmset`.
  - Wired `HapticEngine.snap()` + `LiquidIndicatorDot` to the `autoDisableOnAC` footer pill and `HapticEngine.tap()` to the Nerd Console drawer toggle.
- **Menu Bar Panel & Diagnostic Drawer (`StatusItemManager.swift`, `MenuBarPopoverView.swift`, `NerdDashboardView.swift`)**:
  - Upgraded `StatusBarPanel` show/close transitions to interruptible `NSAnimationContext` downward-expand / upward-retract frame+alpha animations with generation-guarded completion (`panelAnimationGeneration`, `isPanelTargetVisible`) and `HapticEngine.tap()`.
  - Added `HapticEngine.toggle()` + spring squash-and-rebound on popover cat click, `HapticEngine.snap()` + `LiquidIndicatorDot` on `autoDisableOnAC` toggle, and `HapticEngine.tap()` on expand.
  - Added 28ms-staggered `bentoReveal` opacity + slide-in card reveal in `NerdDashboardView`.
- **Version Bump (`2.0.0` -> `2.1.0`)**:
  - Updated `build_app.sh`, `AppVersion.swift`, and `AppVersionTests.swift` to `2.1.0`.

## 3. Files Created or Modified
- `Sources/SleepControl/Services/HapticEngine.swift` (Created)
- `Sources/SleepControl/Views/Components/EditorialTheme.swift` (Modified)
- `Sources/SleepControl/Views/MainWindowView.swift` (Modified)
- `Sources/SleepControl/Services/StatusItemManager.swift` (Modified)
- `Sources/SleepControl/Views/MenuBarPopoverView.swift` (Modified)
- `Sources/SleepControl/Views/NerdDashboardView.swift` (Modified)
- `Sources/SleepControl/Services/AppVersion.swift` (Modified)
- `Tests/SleepControlTests/AppVersionTests.swift` (Modified)
- `build_app.sh` (Modified)
- `dev_logs/2026-11-17_dopamine_microinteractions_v2_1_0.md` (Created)
- `key_decisions/ui_and_macos_aesthetic.md` (Modified)

## 4. Verification & Testing Results
- `swift test`: Passed 35/35 tests across 4 suites (`Activity Log Localization & Retention Tests`, `Application Version Resolution & Localization Tests`, `Core Functional Parity & Hardware Telemetry Tests`, `Editorial Chic UI & Functional Parity Tests`).
- `./build_app.sh`: Release build & ad-hoc codesign succeeded (`SleepControl.app`, `CFBundleShortVersionString` verified as `2.1.0`).
