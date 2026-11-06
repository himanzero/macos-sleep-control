# Dev Log: Dashboard Version Display Implementation

- **Timestamp**: 2026-11-06T14:24:00Z
- **Author**: worker_m5 (Worker M5 - Dashboard Version Display Implementer)
- **Topic**: Subtle & Elegant Dashboard Version Number Display, Dynamic Bundle Lookup, Multi-Tier Safe Fallback & 5-Language i18n Localization (Milestone M5 / R1, R2)

---

## 1. Context & Motivation
Users and testers require an effortless, clear visual confirmation of the running `SleepControl` application version to quickly verify update installations, diagnose issues, and ensure parity across test environments. Prior to this implementation, the version number was defined exclusively in `build_app.sh` and embedded inside `SleepControl.app/Contents/Info.plist`, but was nowhere visible within the user-facing UI.

The user request called for:
- **R1**: Displaying the application version number (e.g. `"v1.1.2"`) in the empty area at the bottom-left corner of the dashboard interface (`MainWindowView.swift`) as static text with no click interactions.
- **R2**: Styling the version number subtly and elegantly using secondary/tertiary hierarchy with muted opacity so that it remains legible while not distracting from main dashboard controls.

---

## 2. Technical Decisions Made

1. **Dedicated Dynamic Version Utility (`AppVersion.swift`)**:
   - Encapsulated version lookup into a pure Swift namespace enum `AppVersion` (`Sources/SleepControl/Services/AppVersion.swift`).
   - Implemented dynamic lookup via `Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")` as the primary tier.
   - Provided a secondary development-mode inspection checking local `SleepControl.app` when launched unbundled (e.g. during CLI runs).
   - Provided a tertiary compile-time fallback constant `fallbackVersion = "1.1.2"` to ensure zero runtime crashes and sensible defaults even in bare checkouts.
   - Implemented leading `"v"` / `"V"` prefix stripping in `raw()` to guarantee raw version consistency and prevent double-prefixing (e.g. `"vv1.1.2"`).

2. **In-Flow Footer Placement in `MainWindowView`**:
   - Placed `dashboardFooterSection` as the final element within `MainWindowView`'s `ScrollView > VStack` below the bottom Bento row (`telemetryCard` and `activityLogCard`).
   - Using in-flow layout rather than a pinned floating overlay prevents visual collisions when the dashboard window is resized down to minimum height (`minHeight: 750pt`), scrolling naturally below the cards.
   - Applied `.padding(.top, -6)` to yield an elegant 12pt visual clearance below the bottom Bento cards, preserving window geometry at standard 850×830 dimensions.

3. **Tertiary Typography Scale & Zero Interaction**:
   - Styled with `.font(.system(size: 11, weight: .regular, design: .monospaced))`, matching the typography of command metadata (`pmset -g`) and activity log timestamps.
   - Applied `.foregroundStyle(.tertiary)` for subtle vibrancy adaptation and automatic system high-contrast support.
   - Applied `.lineLimit(1)` and `.allowsHitTesting(false)`. Disabling hit-testing prevents cursor changes, click interceptions, and text selection, while allowing users to click and drag the window background freely (`window.isMovableByWindowBackground = true`).

4. **Universal 5-Language i18n Localization**:
   - Complied with `app_development_guide` strict zero-hardcoded-strings policy.
   - Added `"dashboard.version" = "v%@";` across all 5 `.lproj` catalogs:
     - `en.lproj/Localizable.strings`
     - `zh-Hans.lproj/Localizable.strings`
     - `zh-Hant-TW.lproj/Localizable.strings`
     - `zh-Hant-HK.lproj/Localizable.strings`
     - `ja.lproj/Localizable.strings`
   - Rendered in UI via `LF("dashboard.version", AppVersion.raw())`.

5. **AppController Convenience Accessors**:
   - Added `appVersionString` (raw version) and `appVersionDisplayString` (prefixed display string) on `AppController` for seamless ViewModel access.

---

## 3. Files Created or Modified

- `Sources/SleepControl/Services/AppVersion.swift` (New): Dynamic version resolution service with multi-tier fallbacks and prefix sanitization.
- `Sources/SleepControl/Views/MainWindowView.swift` (Modified): Added `dashboardFooterSection` in bottom Bento row footer.
- `Sources/SleepControl/Services/AppController.swift` (Modified): Added `appVersionString` and `appVersionDisplayString` computed properties.
- `Sources/SleepControl/Resources/en.lproj/Localizable.strings` (Modified): Added `"dashboard.version" = "v%@";`.
- `Sources/SleepControl/Resources/zh-Hans.lproj/Localizable.strings` (Modified): Added `"dashboard.version" = "v%@";`.
- `Sources/SleepControl/Resources/zh-Hant-TW.lproj/Localizable.strings` (Modified): Added `"dashboard.version" = "v%@";`.
- `Sources/SleepControl/Resources/zh-Hant-HK.lproj/Localizable.strings` (Modified): Added `"dashboard.version" = "v%@";`.
- `Sources/SleepControl/Resources/ja.lproj/Localizable.strings` (Modified): Added `"dashboard.version" = "v%@";`.
- `Tests/SleepControlTests/AppVersionTests.swift` (New): 6 unit tests covering raw/formatted resolution, fallback behavior, prefix deduplication, AppController integration, and 5-locale i18n resolution.
- `key_decisions/ui_and_macos_aesthetic.md` (Modified): Documented Decision 6 on dashboard version display hierarchy and layout.
- `dev_logs/2026-11-06_dashboard_version_display.md` (New): Dev log entry.

---

## 4. Verification & Testing Results

1. **Compilation (`swift build`)**:
   - Built with code 0 in 1.92s without warnings or errors.
2. **Unit Test Suite (`swift test`)**:
   - Total tests executed: 23 across 2 suites (`ActivityLogTests`: 17 tests, `AppVersionTests`: 6 tests).
   - All 23 tests passed in 0.025s with 0 regressions.
3. **Application Packaging (`./build_app.sh`)**:
   - Assembled `SleepControl.app` release bundle with ad-hoc code signature and verified `CFBundleShortVersionString` resolution.
4. **Clean Git Working Tree**:
   - Verified no leftover temporary files or build clutter outside `.build/`.
   - Adhered strictly to zero auto-commit protocol.

---

## 5. Iteration 2 Remediation: Screenshot Export Clipping & Layout Polish

- **Timestamp**: 2026-11-06T14:53:00Z
- **Author**: worker_m5 (Worker M5 - Iteration 2 Implementer)
- **Context & Motivation**:
  - Challenger 2 detected that in `docs/assets/dashboard_en.png`, the version string `v1.1.2` was clipped off because multi-line English text in the Bento cards expanded content height to 910pt, while the headless snapshot window height was hardcoded to 875pt in `ScreenshotExporter.swift`.
- **Technical Decisions & Changes**:
  1. `Sources/SleepControl/Services/ScreenshotExporter.swift` (lines 17 & 32):
     - Updated snapshot window dimensions for both English and Simplified Chinese dashboard exports from `NSSize(width: 850, height: 875)` to `NSSize(width: 850, height: 920)`.
     - Preserves uniform 850×920pt (Retina @2x: 1700×1840px) resolution across documentation assets.
  2. `Sources/SleepControl/Views/MainWindowView.swift` (line 14):
     - Refined `VStack(alignment: .leading, spacing: 18)` to `spacing: 16`, aligning with the standard macOS 8pt grid metrics and reclaiming 8pt of clean vertical headroom across all locales while maintaining full Bento card visual elegance.
  3. Screenshot Regeneration (`docs/assets/`):
     - Re-exported `dashboard_en.png` and `dashboard_zh.png` using `swift run SleepControl --export-screenshots docs/assets`.
     - Verified pixel dimensions at 1700×1840 px.
  4. Apple Vision Framework OCR Validation:
     - Verified `v1.1.2` detection:
       - `docs/assets/dashboard_en.png`: `"v1.1.2"` cleanly detected at normalized coordinates `(x: 0.0266, y: 0.0142)`.
       - `docs/assets/dashboard_zh.png`: `"v1.1.2"` cleanly detected at normalized coordinates `(x: 0.0266, y: 0.0622)`.
  5. Test Suite & Packaging Verification:
     - `swift test`: 23 tests passed in 0.026s.
     - `./build_app.sh`: Assembled `SleepControl.app` release bundle successfully with code 0.

