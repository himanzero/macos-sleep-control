# Dev Log: Hardware Clamshell Detection & Zero-Polling Power Event Handling

- **Timestamp**: 2026-11-05T17:45:00Z
- **Author**: worker_core_power (Worker 1), worker_localization (Worker 2), worker_test_doc_build (Worker 3)
- **Topic**: Hardware Clamshell Detection, Zero-Polling Darwin Notifications, Serialized Power Transitions, Termination Recovery & Multilingual Verification (R1–R6)

---

## 1. Context & Motivation
MacBook users who utilize external displays in clamshell mode (lid closed) while connected to AC power frequently disconnect the power cable to transition to portability. Previously, SleepControl automatically reverted `disablesleep 0` upon detecting battery power, but this created a critical race condition: macOS `powerd` received the power disconnect event and evaluated whether to sleep before SleepControl finished clearing `disablesleep 1`. As a consequence, `powerd` permanently dropped the clamshell sleep trigger, leaving the MacBook awake and running with the lid closed on battery—causing severe battery drain and overheating in laptop bags.

Furthermore, SleepControl relied on a periodic 4.0-second timer loop that repeatedly invoked `pmset -g` and `sudo -n -l /usr/bin/pmset`, causing continuous background CPU wakeups, battery waste, and audit log clutter. In addition, abnormal crashes or termination could leave `SleepDisabled == 1` lingering indefinitely.

---

## 2. Technical Decisions Made

1. **Hardware Clamshell Detection via IOKit (`IOPMrootDomain`)**:
   - Added `isClamshellClosed() -> Bool` in `PowerMonitor.swift`.
   - Utilizes `IOServiceMatching("IOPMrootDomain")` and `IORegistryEntryCreateCFProperty` to directly query the kernel property `AppleClamshellState`.
   - Runs in < 0.2ms with zero subprocess overhead. Desktop Macs safely return `false`.

2. **Native Immediate Sleep via `IOPMSleepSystem`**:
   - Added `sleepSystemNow() -> Bool` in `PowerMonitor.swift`.
   - Calls `IOPMSleepSystem(IOPMFindPowerManagement(kIOMainPortDefault))` from `IOKit.pwr_mgt`.
   - Bypasses child processes, AppleScript permissions, and root/sudo privilege requirements; callable directly by the console user session.

3. **Zero-Polling Event-Driven Preference Telemetry**:
   - Removed the 4.0-second repeating timer (`refreshTimer`) in `AppController.swift`.
   - Registered a Darwin notification observer via `CFNotificationCenterGetDarwinNotifyCenter()` for `com.apple.powermanagement.preferencechanged`.
   - Invokes lightweight `refreshTelemetryOnly()` reading `pmset -g` and power snapshots, guarded with `!isBusy` to suppress circular triggers from internal changes.
   - Decoupled `refreshPasswordlessStatus()` (`sudo -n -l`) to execute on-demand when the user opens the menu bar panel or main window.

4. **Serialized AC-to-Battery Clamshell Sleep Pipeline**:
   - Implemented `setSleepDisabledAsync(_:reasonKey:isAutomated:) async -> Bool` in `AppController.swift`.
   - On AC-to-battery disconnect: awaits completion of `pmset -a disablesleep 0` in the kernel, immediately evaluates `powerMonitor.isClamshellClosed()`, and if closed, triggers `powerMonitor.sleepSystemNow()`.
   - Logs the event via `logClamshellSleep()` with localized strings.

5. **Dual Lifecycle Protection (Termination & Startup Recovery)**:
   - Added `applicationWillTerminate(_:)` in `AppDelegate` (`SleepControlApp.swift`): synchronously executes `setSleepDisabled(false)` if `isSleepDisabled && isPasswordlessConfigured` before application process exit.
   - Added startup recovery in `AppController.init()`: if launched on battery power while `isSleepDisabled == true` (e.g., following a hard power-off, system crash, or `SIGKILL`), immediately executes asynchronous sleep recovery with reason key `msg.reason.startup_battery_recovery`.

6. **Five-Language Localization & Verification**:
   - Added `msg.power.clamshell_sleep.title`, `msg.power.clamshell_sleep.detail`, and `msg.reason.startup_battery_recovery` across `en`, `zh-Hans`, `zh-Hant-TW`, `zh-Hant-HK`, and `ja`.
   - Formatted using standard macOS terminology (e.g. "闔蓋" for Taiwan, "合蓋" for Hong Kong, "合盖" for Simplified Chinese, "クラムシェル" for Japanese).

7. **Comprehensive Unit Testing Suite**:
   - Updated `Tests/SleepControlTests/ActivityLogTests.swift`.
   - Integrated new keys into `requiredKeys` integrity verification.
   - Added multilingual coverage to `testAllSupportedLocalesResolution` and `testAllLogEventTypesDynamicLanguageSwitching`.
   - Implemented dedicated test `testClamshellSleepAndStartupBatteryRecoveryLocalization` asserting exact localized titles/details and dynamic hot-switching without restart.

---

## 3. Files Created or Modified

- `Sources/SleepControl/Services/PowerMonitor.swift`: Added `isClamshellClosed()` and `sleepSystemNow()` via IOKit.
- `Sources/SleepControl/Services/AppController.swift`: Removed 4.0s timer; registered Darwin notification observer for `com.apple.powermanagement.preferencechanged`; added `refreshTelemetryOnly()`, `refreshPasswordlessStatus()`, `setSleepDisabledAsync()`, serialized AC-to-battery clamshell transition, startup recovery, and `logClamshellSleep()`.
- `Sources/SleepControl/SleepControlApp.swift`: Added `applicationWillTerminate(_:)` synchronous cleanup.
- `Sources/SleepControl/Services/StatusItemManager.swift`: Hooked on-demand `refreshPasswordlessStatus()` when opening menu bar panel or main window.
- `Sources/SleepControl/Resources/en.lproj/Localizable.strings`: Added English localization keys.
- `Sources/SleepControl/Resources/zh-Hans.lproj/Localizable.strings`: Added Simplified Chinese localization keys.
- `Sources/SleepControl/Resources/zh-Hant-TW.lproj/Localizable.strings`: Added Traditional Chinese (Taiwan) localization keys.
- `Sources/SleepControl/Resources/zh-Hant-HK.lproj/Localizable.strings`: Added Traditional Chinese (Hong Kong) localization keys.
- `Sources/SleepControl/Resources/ja.lproj/Localizable.strings`: Added Japanese localization keys.
- `Tests/SleepControlTests/ActivityLogTests.swift`: Added unit test coverage for new keys and dedicated clamshell/recovery localization test suite.
- `key_decisions/power_management_and_iokit.md`: Documented 5 architectural decisions covering IOKit lid detection, `IOPMSleepSystem`, zero-polling Darwin notification, serialized transitions, and dual lifecycle recovery.
- `dev_logs/2026-11-05_clamshell_detection_and_zero_polling.md`: Created development log.

---

## 4. Verification & Testing Results

- `plutil -lint Sources/SleepControl/Resources/*.lproj/Localizable.strings`: Passed with 0 errors across all 5 languages.
- `swift test`: 17/17 tests passed cleanly in 0.024 seconds (including new dedicated clamshell sleep and startup battery recovery tests).
- `./build_app.sh`: Successfully compiled Release binary and assembled `SleepControl.app` bundle with ad-hoc code signature.
- Git cleanliness: Strict adherence to zero-commit policy; no lingering scratch/temporary files.
