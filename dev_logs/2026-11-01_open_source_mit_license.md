# Dev Log: GitHub Open Source Preparation, MIT License & Retina UI Screenshots

- **Date**: 2026-11-01
- **Author**: Antigravity Assistant & himanzero
- **Project**: SleepControl (`app-mac-sleep-control`)

## 1. Context & Motivation
User evaluated publishing `SleepControl` to GitHub as an open-source macOS utility and requested adding high-resolution UI screenshots to `README.md` for better visual presentation.

## 2. Review & Changes
1. **Privacy & Security Audit**:
   - Verified that no private API keys, secrets, local path references, or private network endpoints were present in tracked files.
2. **License Added**:
   - Added `LICENSE` adopting the permissive MIT License (Copyright (c) 2026 himanzero).
3. **Retina UI Screenshot Exporter**:
   - Created `Sources/SleepControl/Services/ScreenshotExporter.swift` using `NSHostingView` + off-screen `NSWindow` display caching (`cacheDisplay(in:to:)`) so AppKit-backed controls (`Toggle`, `Menu`) render faithfully at 2x Retina resolution.
   - Refined `StatusHeroCard.swift` badge sizing and radial glow clipping for crisp compact-popover rendering.
   - Generated `docs/assets/app_icon.png`, `docs/assets/dashboard_en.png`, `docs/assets/dashboard_zh.png`, `docs/assets/menubar_popover_en.png`, and `docs/assets/menubar_popover_zh.png`.
4. **README Documentation Enhanced**:
   - Centered app icon header and standard GitHub badges (Platform, Language, License, Architecture).
   - Added side-by-side English and Simplified Chinese screenshots for both the Bento Control Dashboard and the Menu Bar Quick Popover.
   - Documented feature highlights, AC power automation mechanics, build instructions, and security boundaries.

## 3. Verification
- Verified all 5 generated PNG assets in `docs/assets/` for layout fidelity, zero clipping, and Retina sharpness.
- Validated `LICENSE` and `README.md` formatting.
