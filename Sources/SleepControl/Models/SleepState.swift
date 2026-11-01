import Foundation

/// Power connection type
enum PowerSourceKind: String, Equatable {
    case ac = "AC Power"
    case battery = "Battery Power"
    case unknown = "Unknown"

    var displayName: String {
        switch self {
        case .ac:
            return L("power.source.ac")
        case .battery:
            return L("power.source.battery")
        case .unknown:
            return L("power.source.unknown")
        }
    }

    var shortBadgeText: String {
        switch self {
        case .ac:
            return L("power.badge.ac")
        case .battery:
            return L("power.badge.battery")
        case .unknown:
            return L("power.badge.unknown")
        }
    }

    var symbolName: String {
        switch self {
        case .ac:
            return "bolt.fill"
        case .battery:
            return "battery.75percent"
        case .unknown:
            return "powerplug"
        }
    }
}

/// Real-time battery and power source snapshot
struct PowerSnapshot: Equatable {
    var source: PowerSourceKind = .unknown
    var batteryPercentage: Int? = nil
    var isCharging: Bool = false
    var isCharged: Bool = false

    var formattedSummary: String {
        if let pct = batteryPercentage {
            switch source {
            case .ac:
                let status = isCharging
                    ? L("power.status.charging")
                    : (isCharged ? L("power.status.charged") : L("power.status.external"))
                return LF("power.summary.ac", source.displayName, pct, status)
            case .battery:
                return LF("power.summary.battery", source.displayName, pct)
            case .unknown:
                return "\(pct)%"
            }
        }
        return source.displayName
    }
}

/// Low-level pmset telemetry snapshot (stores raw values, formatted dynamically by active language)
struct PmsetTelemetry: Equatable {
    /// SleepDisabled (1 = Sleep Disabled, 0 = Sleep Allowed)
    var isSleepDisabled: Bool = false
    /// Display sleep raw value (displaysleep)
    var rawDisplaySleep: String = "--"
    /// Hibernate mode raw value (hibernatemode)
    var rawHibernateMode: String = "--"
    /// System sleep raw value (sleep)
    var rawSystemSleep: String = "--"
    /// Low power mode raw value (lowpowermode)
    var rawLowPowerMode: String = "--"
    /// Raw output snippet from `pmset -g`
    var rawOutput: String = ""

    var displaySleepFormatted: String {
        guard rawDisplaySleep != "--" else { return "--" }
        return rawDisplaySleep == "0" ? L("telemetry.val.never") : LF("telemetry.val.minutes", rawDisplaySleep)
    }

    var hibernateModeFormatted: String {
        guard rawHibernateMode != "--" else { return "--" }
        return LF("telemetry.val.mode", rawHibernateMode)
    }

    var systemSleepFormatted: String {
        guard rawSystemSleep != "--" else { return "--" }
        return rawSystemSleep == "0" ? L("telemetry.val.disabled_zero") : LF("telemetry.val.minutes", rawSystemSleep)
    }

    var lowPowerModeFormatted: String {
        guard rawLowPowerMode != "--" else { return "--" }
        return rawLowPowerMode == "1" ? L("telemetry.val.on") : L("telemetry.val.off")
    }
}

/// Activity log item model
struct ActivityLogItem: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let detail: String
    let isSuccess: Bool
    let isAutomated: Bool

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
