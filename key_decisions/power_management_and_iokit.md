# Key Decisions: Power Management & IOKit Integration

## Decision: Event-Driven Power Source Monitoring via IOKit.ps
- **Status**: Accepted
- **Context**: The app needs to know when the user connects or disconnects the AC power adapter in order to automatically toggle `pmset -a disablesleep 1` or `0`.
- **Options Considered**:
  1. *Polling loop with `pmset -g batt` or `IOPSCopyPowerSourcesInfo` every N seconds*:
     - *Pros*: Simple to implement.
     - *Cons*: Keeps CPU waking up, wastes battery power, introduces up to N-second latency.
  2. *Hardware RunLoop Callback via `IOPSNotificationCreateRunLoopSource`*:
     - *Pros*: Zero background CPU overhead when idle; triggers immediately within milliseconds when the power cable is plugged or unplugged.
     - *Cons*: Requires unmanaged C pointer bridging to Swift run loop.
- **Decision Outcome**: Implemented option 2 (`PowerMonitor.swift`). The callback is registered on `CFRunLoopGetMain()` and invokes Swift handlers safely on `@MainActor`. `pmset -g batt` is retained solely as an emergency fallback parser.
- **Consequences**: Instantaneous response to power cable connection/disconnection with negligible energy footprint.

---

## Decision: Direct Hardware Clamshell State Inspection via IOKit `IOPMrootDomain`
- **Status**: Accepted
- **Context**: macOS `powerd` can miss clamshell sleep events if `disablesleep` is set to `1` at the exact moment the lid is closed or the power adapter is disconnected. To make deterministic power enforcement decisions, the application must authoritatively query whether the MacBook lid is physically closed.
- **Options Considered**:
  1. *Periodic polling or spawning shell utilities (`ioreg -r -k AppleClamshellState`)*:
     - *Pros*: Simple shell command.
     - *Cons*: Forking subprocesses introduces 15–30ms latency, high CPU overhead, and wastes battery.
  2. *Private Apple frameworks (e.g. `DisplayServices` or `CoreDisplay`)*:
     - *Pros*: May provide high-level Objective-C bindings.
     - *Cons*: Fragile, unversioned, and subject to runtime breakage or macOS notarization/security concerns.
  3. *Direct kernel registry inspection via `IOServiceMatching("IOPMrootDomain")` and `IORegistryEntryCreateCFProperty`*:
     - *Pros*: Official, stable public IOKit API; query completes in under 0.2ms; zero subprocess overhead; non-laptop Macs (desktop/iMac) safely return `false`.
     - *Cons*: Requires unmanaged CoreFoundation memory management (`IOObjectRelease`).
- **Decision Outcome**: Implemented option 3 in `PowerMonitor.isClamshellClosed()`. The function locates `IOPMrootDomain` via `IOServiceGetMatchingService`, reads `AppleClamshellState` as a CFBoolean, and cleanly releases the IO object.
- **Consequences**: Authoritative, microsecond-latency physical lid detection with zero process spawning overhead and zero security risks.

---

## Decision: Native Demanded System Sleep via `IOPMSleepSystem`
- **Status**: Accepted
- **Context**: When transitioning from AC to battery while the MacBook lid is closed, SleepControl restores `disablesleep 0`. However, macOS `powerd` evaluated the lid state before `disablesleep` cleared and will not automatically re-evaluate. The application must immediately command the system into sleep.
- **Options Considered**:
  1. *Spawning subprocesses (`pmset sleepnow` or AppleScript System Events)*:
     - *Pros*: Well-known CLI commands.
     - *Cons*: Subprocess creation latency; `pmset sleepnow` requires root privileges or passwordless sudo; AppleScript triggers automation privacy dialogs.
  2. *Direct IOKit kernel call `IOPMSleepSystem(IOPMFindPowerManagement(kIOMainPortDefault))`*:
     - *Pros*: Native C API in `IOKit.pwr_mgt`; directly available to the GUI console user session without root or sudo permissions; commands the kernel power plane immediately.
     - *Cons*: Requires bridging C types; sleep can still be delayed if external kernel drivers hold sleep assertions.
- **Decision Outcome**: Implemented option 2 in `PowerMonitor.sleepSystemNow()`.
- **Consequences**: Fast, reliable, privilege-free system sleep trigger without spawning child processes or requiring sudoers privileges.

---

## Decision: Zero-Polling Preference Telemetry via Darwin Notifications
- **Status**: Accepted
- **Context**: SleepControl must stay synchronized with external configuration changes (e.g. command-line `pmset` executions or third-party tools). Previously, a 4.0-second repeating timer ran in `AppController`, continuously executing `pmset -g` and `sudo -n -l /usr/bin/pmset`.
- **Options Considered**:
  1. *Periodic 4.0-second timer loop*:
     - *Pros*: Simple timer mechanism.
     - *Cons*: Constant CPU timer wakeups prevent CPU package deep C-states; repeatedly spawning `sudo -n -l` subprocesses wastes battery and floods system logs.
  2. *Darwin notification listener for `com.apple.powermanagement.preferencechanged`*:
     - *Pros*: Purely event-driven; macOS `powerd` posts this notification whenever power management preferences update; zero CPU consumption when idle; internal toggles are guarded with `!isBusy` to prevent circular updates; passwordless privilege checks are decoupled to on-demand UI presentation.
     - *Cons*: Requires registering a C function pointer callback on `CFNotificationCenterGetDarwinNotifyCenter()` and deregistering on `deinit`.
- **Decision Outcome**: Implemented option 2 in `AppController.setupPreferenceChangeObserver()`.
- **Consequences**: Complete elimination of idle timer wakeups; telemetry updates in real-time upon external modification; privilege checks run only when UI is displayed.

---

## Decision: Serialized AC-to-Battery Clamshell Transition Pipeline
- **Status**: Accepted
- **Context**: When the user disconnects the power adapter with the lid closed, an asynchronous race condition occurs: macOS `powerd` receives the power disconnect event and evaluates clamshell sleep immediately. Because `SleepDisabled == 1` was active on AC, `powerd` aborts sleep. If SleepControl toggles `disablesleep 0` in an uncoordinated manner, the sleep event remains dropped.
- **Options Considered**:
  1. *Uncoordinated asynchronous dispatch*:
     - *Pros*: Simple fire-and-forget.
     - *Cons*: Fails to eliminate the race condition; the system remains awake with the lid closed on battery.
  2. *Serialized async pipeline (`setSleepDisabledAsync` -> await -> inspect lid -> `sleepSystemNow()`)*:
     - *Pros*: Guarantees that `pmset -a disablesleep 0` has completely committed in the kernel IOPMrootDomain before inspecting `isClamshellClosed()`. If the lid is closed, `sleepSystemNow()` is invoked immediately to recover the dropped sleep event and logged with localized telemetry.
     - *Cons*: Requires async/await synchronization in `AppController`.
- **Decision Outcome**: Implemented option 2 in `AppController.handlePowerSnapshotUpdate(_:)`.
- **Consequences**: Prevents battery drain and overheating in bags; guarantees reliable sleep when unplugged in clamshell mode.

---

## Decision: Dual Lifecycle Recovery for Sleep Policy Integrity
- **Status**: Accepted
- **Context**: If SleepControl terminates while `SleepDisabled == 1` (e.g., normal user quit, logout, or abnormal crashes), the system could be left with sleep permanently disabled on battery.
- **Options Considered**:
  1. *Rely on user manual intervention*:
     - *Pros*: No additional code.
     - *Cons*: High risk of battery drain and system damage if the user assumes default macOS behavior.
  2. *Dual lifecycle protection (`applicationWillTerminate` synchronous cleanup + startup battery recovery)*:
     - *Pros*: 
       - Clean exits (Cmd+Q, system shutdown/logout) are captured by `applicationWillTerminate(_:)` in `AppDelegate`, which synchronously invokes `SleepManager.shared.setSleepDisabled(false, allowInteractiveAuth: false)` before process exit.
       - Abnormal exits (crashes, `SIGKILL`, hard power-offs) are caught on next launch in `AppController.init()`: if running on battery and `SleepDisabled == 1` is detected, it immediately restores `disablesleep 0` with reason `msg.reason.startup_battery_recovery`.
     - *Cons*: Requires coordinating app lifecycle events with privileged execution.
- **Decision Outcome**: Implemented option 2.
- **Consequences**: Bulletproof sleep policy recovery under both normal and abnormal application termination scenarios.
