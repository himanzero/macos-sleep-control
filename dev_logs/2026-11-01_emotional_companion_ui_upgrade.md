# Dev Log: 2026-11-01 — Emotional Companion UI & Aurora Aesthetic Upgrade

## Summary
Upgraded `SleepControl.app` from a utilitarian system dashboard into a living, high-emotional-value desktop companion experience across four core dimensions:

1. **Companion Hero Stage (`CompanionCatStage` in `StatusHeroCard.swift`)**:
   - Generated high-resolution full-detail companion assets (`Resources/hero_cat_awake.png`, `Resources/hero_cat_awake@2x.png`, `Resources/hero_cat_sleeping.png`, `Resources/hero_cat_sleeping@2x.png`) from the original cat artwork using exterior flood-fill and un-premultiplied white alpha edges, preserving 3D fur shading, ears, whiskers, eyes, crescent moon, and alert marks.
   - Built an illuminated scene orb (Golden Sunrise when keeping Mac awake vs. Starry Night Nebula when sleep is allowed) with a companion mood badge (`companion.mood.awake.badge` / `companion.mood.sleep.badge`) alongside the `disablesleep 1 / 0` telemetry pill.
2. **Living Micro-Animations**:
   - Powered continuous breathing motion, vertical float, and outer aura pulsing via `TimelineView(.animation)`.
   - Added state-specific living particles: drifting `"z"` / `"Z"` sleep bubbles and twinkling star dots when sleeping, and pulsing golden `sparkles` / `bolt.fill` badges when awake.
   - Added interactive petting (`controller.petCompanion()`): clicking the cat or speech bubble triggers a spring bounce, pops a floating pink heart (`heart.fill`), and cycles through 3 companion quotes per state.
3. **Emotional & Companion Copywriting (5 Locales)**:
   - Added localized companion mood badges, interactive pet hints, 6 first-person companion quotes (`companion.quote.awake.0..2`, `companion.quote.sleep.0..2`), and power-transition companion banner notifications (`msg.power.ac_companion_banner`, `msg.power.battery_companion_banner`) across `en`, `zh-Hans`, `zh-Hant-TW`, `zh-Hant-HK`, and `ja`.
4. **Dynamic Multi-Layer Aurora Frosted Glass (`AuroraAmbientBackdrop`)**:
   - Upgraded `AppTheme` to 3-stop gradients and added drifting radial Aurora nebula orbs to `MainWindowView`, `MenuBarPopoverView`, and `StatusHeroCard`.
   - Refreshed all README screenshots (`docs/assets/dashboard_en.png`, `docs/assets/dashboard_zh.png`, `docs/assets/menubar_popover_en.png`, `docs/assets/menubar_popover_zh.png`) and the GitHub Social Preview banner (`docs/assets/social_preview.png`).
