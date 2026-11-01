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
