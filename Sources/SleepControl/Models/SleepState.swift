import Foundation

/// Power connection type
enum PowerSourceKind: String, Equatable {
    case ac = "AC Power"
    case battery = "Battery Power"
    case unknown = "Unknown"

    func localizedDisplayName(in language: AppLanguage? = nil) -> String {
        switch self {
        case .ac:
            return I18n.shared.localized("power.source.ac", in: language)
        case .battery:
            return I18n.shared.localized("power.source.battery", in: language)
        case .unknown:
            return I18n.shared.localized("power.source.unknown", in: language)
        }
    }

    var displayName: String {
        localizedDisplayName()
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

    func formattedSummary(in language: AppLanguage? = nil) -> String {
        if let pct = batteryPercentage {
            switch source {
            case .ac:
                let status = isCharging
                    ? I18n.shared.localized("power.status.charging", in: language)
                    : (isCharged
                        ? I18n.shared.localized("power.status.charged", in: language)
                        : I18n.shared.localized("power.status.external", in: language))
                let sourceName = source.localizedDisplayName(in: language)
                return I18n.shared.format("power.summary.ac", in: language, args: [sourceName, pct, status])
            case .battery:
                let sourceName = source.localizedDisplayName(in: language)
                return I18n.shared.format("power.summary.battery", in: language, args: [sourceName, pct])
            case .unknown:
                return "\(pct)%"
            }
        }
        return source.localizedDisplayName(in: language)
    }

    var formattedSummary: String {
        formattedSummary(in: nil)
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

/// Dynamic parameter for localized activity log messages
enum ActivityLogParameter: Equatable {
    case string(String)
    case localizedKey(String)
    case sleepState(isSleepDisabled: Bool)
    case powerSnapshot(PowerSnapshot)
    case error(SleepControlError)

    func resolve(in language: AppLanguage? = nil) -> String {
        switch self {
        case .string(let str):
            return str
        case .localizedKey(let key):
            return I18n.shared.localized(key, in: language)
        case .sleepState(let disabled):
            return I18n.shared.localized(disabled ? "telemetry.val.disabled" : "telemetry.val.enabled", in: language)
        case .powerSnapshot(let snapshot):
            return snapshot.formattedSummary(in: language)
        case .error(let err):
            return err.localizedErrorDescription(in: language)
        }
    }
}

/// Activity log item model supporting dynamic runtime re-localization across languages
struct ActivityLogItem: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let titleKey: String
    let titleArgs: [ActivityLogParameter]
    let detailKey: String?
    let detailArgs: [ActivityLogParameter]
    let customDetailFormat: String?
    let isSuccess: Bool
    let isAutomated: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        titleKey: String,
        titleArgs: [ActivityLogParameter] = [],
        detailKey: String? = nil,
        detailArgs: [ActivityLogParameter] = [],
        customDetailFormat: String? = nil,
        isSuccess: Bool,
        isAutomated: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.titleKey = titleKey
        self.titleArgs = titleArgs
        self.detailKey = detailKey
        self.detailArgs = detailArgs
        self.customDetailFormat = customDetailFormat
        self.isSuccess = isSuccess
        self.isAutomated = isAutomated
    }

    /// Backward compatibility initializer for plain pre-rendered strings
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        title: String,
        detail: String,
        isSuccess: Bool,
        isAutomated: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.titleKey = title
        self.titleArgs = []
        self.detailKey = nil
        self.detailArgs = [.string(detail)]
        self.customDetailFormat = "%@"
        self.isSuccess = isSuccess
        self.isAutomated = isAutomated
    }

    /// Resolves the log title into the target language or currently active interface language
    func localizedTitle(in language: AppLanguage? = nil) -> String {
        if titleArgs.isEmpty {
            return I18n.shared.localized(titleKey, in: language)
        }
        let resolved = titleArgs.map { $0.resolve(in: language) as CVarArg }
        return I18n.shared.format(titleKey, in: language, args: resolved)
    }

    private static func countSpecifiers(in pattern: String) -> Int {
        var count = 0
        var iterator = pattern.makeIterator()
        while let char = iterator.next() {
            if char == "%" {
                if let nextChar = iterator.next() {
                    if nextChar != "%" {
                        count += 1
                    }
                } else {
                    count += 1
                }
            }
        }
        return count
    }

    /// Resolves the log detail into the target language or currently active interface language
    func localizedDetail(in language: AppLanguage? = nil) -> String {
        let resolvedArgs = detailArgs.map { $0.resolve(in: language) as CVarArg }
        if let key = detailKey {
            let template = I18n.shared.localized(key, in: language)
            let requiredCount = Self.countSpecifiers(in: template)
            if requiredCount == 0 {
                return template
            }
            if resolvedArgs.isEmpty {
                return ""
            }
            if resolvedArgs.count >= requiredCount {
                return I18n.shared.format(key, in: language, args: resolvedArgs)
            }
            return resolvedArgs.map { String(describing: $0) }.joined(separator: " · ")
        }
        if let formatPattern = customDetailFormat {
            let requiredCount = Self.countSpecifiers(in: formatPattern)
            if requiredCount == 0 {
                return formatPattern
            }
            if resolvedArgs.isEmpty {
                return ""
            }
            if resolvedArgs.count >= requiredCount {
                return String(format: formatPattern, arguments: resolvedArgs)
            }
            return resolvedArgs.map { String(describing: $0) }.joined(separator: " — ")
        }
        return resolvedArgs.map { String(describing: $0) }.joined(separator: " ")
    }

    var title: String {
        localizedTitle()
    }

    var detail: String {
        localizedDetail()
    }

    private static let timeFormatterLock = NSLock()
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var formattedTime: String {
        Self.timeFormatterLock.lock()
        defer { Self.timeFormatterLock.unlock() }
        return Self.timeFormatter.string(from: timestamp)
    }
}
