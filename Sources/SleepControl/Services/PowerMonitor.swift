import Foundation
import IOKit.ps

/// Hardware-level real-time power source and battery monitor based on `IOKit.ps` (zero polling overhead)
final class PowerMonitor {
    typealias PowerChangeHandler = (PowerSnapshot) -> Void

    private var runLoopSource: CFRunLoopSource?
    private var onChange: PowerChangeHandler?

    init() {}

    deinit {
        stopMonitoring()
    }

    /// Starts monitoring IOKit power source notification changes
    func startMonitoring(onChange: @escaping PowerChangeHandler) {
        stopMonitoring()
        self.onChange = onChange

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            let snapshot = monitor.readCurrentPowerSnapshot()
            DispatchQueue.main.async {
                monitor.onChange?(snapshot)
            }
        }

        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            self.runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    /// Stops monitoring
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    /// Reads current power source type and battery snapshot
    func readCurrentPowerSnapshot() -> PowerSnapshot {
        var snapshot = PowerSnapshot()

        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return fallbackReadFromPmsetBatt()
        }

        if let powerTypeCF = IOPSGetProvidingPowerSourceType(blob)?.takeUnretainedValue() as String? {
            if powerTypeCF == kIOPMACPowerKey {
                snapshot.source = .ac
            } else if powerTypeCF == kIOPMBatteryPowerKey {
                snapshot.source = .battery
            } else {
                snapshot.source = .unknown
            }
        }

        if let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] {
            for ps in list {
                guard let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] else {
                    continue
                }
                if let current = desc[kIOPSCurrentCapacityKey as String] as? Int,
                   let max = desc[kIOPSMaxCapacityKey as String] as? Int,
                   max > 0 {
                    snapshot.batteryPercentage = Int((Double(current) / Double(max)) * 100.0)
                }
                if let isCharging = desc[kIOPSIsChargingKey as String] as? Bool {
                    snapshot.isCharging = isCharging
                }
                if let isCharged = desc[kIOPSIsChargedKey as String] as? Bool {
                    snapshot.isCharged = isCharged
                }
                if snapshot.source == .unknown,
                   let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                    if state == kIOPSACPowerValue {
                        snapshot.source = .ac
                    } else if state == kIOPSBatteryPowerValue {
                        snapshot.source = .battery
                    }
                }
                break
            }
        }

        return snapshot
    }

    /// Fallback strategy: parses `pmset -g batt` if IOKit returns unknown
    private func fallbackReadFromPmsetBatt() -> PowerSnapshot {
        var snapshot = PowerSnapshot()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if output.contains("AC Power") {
                snapshot.source = .ac
            } else if output.contains("Battery Power") {
                snapshot.source = .battery
            }
            if let range = output.range(of: "\\d+%", options: .regularExpression) {
                let pctStr = output[range].dropLast()
                snapshot.batteryPercentage = Int(pctStr)
            }
            snapshot.isCharging = output.contains("; charging")
            snapshot.isCharged = output.contains("; charged") || output.contains("not charging")
        } catch {}
        return snapshot
    }
}
