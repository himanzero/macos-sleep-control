# Dev Log: Activity Log i18n Localization & Retention Management

- **Timestamp**: 2026-11-01T16:55:00Z (Updated R3: 2026-11-02T01:32:00Z)
- **Author**: implementer (SWE Light Implementer) / reviewer_r3 (SWE Light Adversarial Reviewer)
- **Topic**: Activity Log Dynamic Localization and Retention Management (R1, R2, R3)

---

## 1. Context & Motivation
Activity log entries in the Recent Activity & Automation Log card were previously constructed as static localized strings at the time of logging (`L(...)` / `LF(...)`), rendering them permanently in the initial language (typically Chinese) and preventing dynamic re-localization when users switched the active interface language. In addition, activity logs lacked age-based pruning (older than 30 days).

## 2. Technical Decisions Made
1. **Dynamic Parameterized Activity Log Representation (`ActivityLogItem`)**:
   - Replaced pre-rendered static strings with a structured representation (`titleKey`, `titleArgs`, `detailKey`, `detailArgs`, `customDetailFormat`).
   - Added an `ActivityLogParameter` enumeration to represent parameters (`.string`, `.localizedKey`, `.sleepState`, `.powerSnapshot`, `.error`) that dynamically resolve against the requested or active language.
   - Preserved `title` and `detail` computed properties for transparent SwiftUI rendering without requiring view redesign.
   - Retained backward-compatible initializer `init(title:detail:isSuccess:isAutomated:)`.

2. **Per-Locale Resolution & Bundle Cache in `I18n`**:
   - Added `bundle(for language: AppLanguage) -> Bundle?` with internal caching for instant retrieval across all 5 supported locales (`en`, `zh-Hans`, `zh-Hant-TW`, `zh-Hant-HK`, `ja`).
   - Enhanced `I18n.localized` and `I18n.format` to accept an explicit `in language: AppLanguage?` parameter.
   - Added `NSLock` synchronization around bundle cache and active language state, streamlined to a single lock acquisition per lookup.
   - Added compile-time `#filePath` directory anchor to guarantee robust bundle lookup regardless of the working directory during test runs.

3. **Retention and Age-Based Pruning**:
   - Implemented `pruneLogs(referenceDate:)` in `AppController` enforcing both:
     - 30-entry maximum capacity buffer (FIFO).
     - 30-day age cutoff (`referenceDate - 30 * 86400`).
   - Fixed `appendLog(...)` to use `Date()` as the canonical reference date, preventing catastrophic deletion of legitimate current logs when events with future timestamps (e.g. clock drift or synthetic logs) are received.

4. **Structured Error Representation, Concurrency & UI Performance**:
   - Added `executionFailedWithCode(Int32)` case to `SleepControlError` for runtime dynamic localization of privileged command exit code failures without eager string formatting on background tasks.
   - Implemented `countSpecifiers` validation for both `customDetailFormat` and parameterized `detailKey`, preventing missing argument `(null)` formatting and format placeholder leaks (`%@`).
   - Synchronized `ActivityLogItem.formattedTime` using `NSLock` around static cached `DateFormatter` with `en_US_POSIX` locale for thread-safe 24-hour time formatting across all user environments (QA1480).
   - Conformed `I18n` and `SleepManager` to `@unchecked Sendable`.
   - Refactored `AppController.appLanguage` property observer from `didSet` to `willSet` to eliminate duplicate notifications and ensure atomic `I18n.shared` synchronization before Combine `objectWillChange` broadcasts.

5. **Automated Unit Test Suite (`swift test`)**:
   - Added `SleepControlTests` target in `Package.swift` configured with dynamic testing plugin candidate search including `DEVELOPER_DIR` support.
   - Implemented 16 comprehensive unit tests covering all locales, dynamic hot-switching across all 8 log types, parameter resolution, catalog integrity across all 5 `.lproj` files, capacity buffer, age pruning, immediate expired log pruning, concurrent language switching stress, exit code error resolution, empty format argument safety, partial format argument safety, detailKey placeholder leak prevention, future timestamp retention safety, and Combine notification atomicity.

## 3. Files Created or Modified
- `Package.swift`: Added `SleepControlTests` test target with adaptive toolchain candidate resolution including `DEVELOPER_DIR`.
- `Sources/SleepControl/Services/I18n.swift`: Streamlined thread-safe bundle caching via `NSLock`, `@unchecked Sendable` conformance, explicit language lookup, safe empty args handling in `format`, and `#filePath` resolution.
- `Sources/SleepControl/Models/SleepState.swift`: Added `ActivityLogParameter`, upgraded `ActivityLogItem` for dynamic localization, POSIX locale thread-safe cached `DateFormatter`, safe format specifier counting for `detailKey` and `customDetailFormat`, added localized formatting to `PowerSourceKind` and `PowerSnapshot`.
- `Sources/SleepControl/Services/SleepManager.swift`: Added `executionFailedWithCode(Int32)` and `localizedErrorDescription(in:)` to `SleepControlError`, conformed `SleepManager` to `@unchecked Sendable`.
- `Sources/SleepControl/Services/AppController.swift`: Atomic `willSet` on `appLanguage`, added semantic logging helpers, `pruneLogs` for 30-item/30-day retention with canonical `Date()` reference, updated power transition and toggle callers.
- `Sources/SleepControl/Views/Components/StatusHeroCard.swift`: Updated main switch binding to pass `reasonKey`.
- `Tests/SleepControlTests/ActivityLogTests.swift`: Added complete unit test suite with 16 tests.

## 4. Verification & Testing Results
- `swift test`: 16/16 unit tests passed cleanly in 0.047s.
- `./build_app.sh`: Full release build and codesign passed cleanly.
