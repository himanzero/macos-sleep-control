import Foundation

/// Supported application language choices (following BCP-47 / Apple .lproj standards)
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case zhHans = "zh-Hans"
    case zhHantTW = "zh-Hant-TW"
    case zhHantHK = "zh-Hant-HK"
    case ja = "ja"

    var id: String { rawValue }

    /// Native localized name displayed in language selector menus
    func displayTitle(in currentBundle: Bundle?) -> String {
        switch self {
        case .system:
            let followText = I18n.shared.localized("lang.option.system", bundleOverride: currentBundle)
            let sysResolved = Self.resolveSystemLanguage()
            return "\(followText) (\(sysResolved.nativeName))"
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .zhHantTW:
            return "繁體中文（台灣）"
        case .zhHantHK:
            return "繁體中文（香港）"
        case .ja:
            return "日本語"
        }
    }

    var nativeName: String {
        switch self {
        case .system:
            return Self.resolveSystemLanguage().nativeName
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .zhHantTW:
            return "繁體中文（台灣）"
        case .zhHantHK:
            return "繁體中文（香港）"
        case .ja:
            return "日本語"
        }
    }

    var shortBadgeCode: String {
        switch self {
        case .system:
            return Self.resolveSystemLanguage().shortBadgeCode
        case .en:
            return "EN"
        case .zhHans:
            return "简"
        case .zhHantTW:
            return "繁TW"
        case .zhHantHK:
            return "繁HK"
        case .ja:
            return "JA"
        }
    }

    /// Corresponding .lproj resource folder name
    var resolvedLprojName: String {
        switch self {
        case .system:
            return Self.resolveSystemLanguage().rawValue
        default:
            return self.rawValue
        }
    }

    /// Resolves system preferred language; falls back to English (.en) if unsupported
    static func resolveSystemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages
        guard let primary = preferred.first?.lowercased() else {
            return .en
        }

        if primary.hasPrefix("zh") {
            // Distinguish Hong Kong / Macau Traditional, Taiwan Traditional, and Simplified Chinese
            if primary.contains("hk") || primary.contains("mo") {
                return .zhHantHK
            }
            if primary.contains("hant") || primary.contains("tw") {
                return .zhHantTW
            }
            return .zhHans
        }

        if primary.hasPrefix("ja") {
            return .ja
        }

        if primary.hasPrefix("en") {
            return .en
        }

        // Fall back to English when system language is outside supported list
        return .en
    }
}

/// Internationalization resource loader and formatting manager
final class I18n: @unchecked Sendable {
    static let shared = I18n()
    static let languageKey = "com.himanzero.SleepControl.appLanguage"

    private let lock = NSLock()
    private var activeBundle: Bundle?
    private var englishFallbackBundle: Bundle?
    private var bundleCache: [String: Bundle] = [:]
    private var _currentLanguage: AppLanguage = .system

    var currentLanguage: AppLanguage {
        lock.lock()
        defer { lock.unlock() }
        return _currentLanguage
    }

    private init() {
        let savedRaw = UserDefaults.standard.string(forKey: Self.languageKey) ?? AppLanguage.system.rawValue
        let lang = AppLanguage(rawValue: savedRaw) ?? .system
        self.englishFallbackBundle = Self.findLprojBundle(named: AppLanguage.en.rawValue)
        setLanguage(lang)
    }

    func setLanguage(_ language: AppLanguage) {
        lock.lock()
        self._currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
        let resolved = resolveBundleLocked(for: language) ?? self.englishFallbackBundle
        self.activeBundle = resolved
        lock.unlock()
    }

    /// Retrieves or caches the bundle for a given AppLanguage
    func bundle(for language: AppLanguage) -> Bundle? {
        lock.lock()
        defer { lock.unlock() }
        return resolveBundleLocked(for: language)
    }

    private func resolveBundleLocked(for language: AppLanguage) -> Bundle? {
        let lprojName = language.resolvedLprojName
        if let cached = bundleCache[lprojName] {
            return cached
        }
        if let found = Self.findLprojBundle(named: lprojName) {
            bundleCache[lprojName] = found
            return found
        }
        return englishFallbackBundle
    }

    func localized(_ key: String, in language: AppLanguage? = nil, bundleOverride: Bundle? = nil) -> String {
        let targetBundle: Bundle?
        let fallback: Bundle?
        lock.lock()
        if let override = bundleOverride {
            targetBundle = override
        } else if let lang = language {
            targetBundle = resolveBundleLocked(for: lang)
        } else {
            targetBundle = activeBundle ?? englishFallbackBundle
        }
        fallback = englishFallbackBundle
        lock.unlock()

        if let bundle = targetBundle {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            if value != key {
                return value
            }
        }
        if let enBundle = fallback {
            let fallbackValue = enBundle.localizedString(forKey: key, value: nil, table: "Localizable")
            return fallbackValue
        }
        return key
    }

    func format(_ key: String, in language: AppLanguage? = nil, args: [CVarArg]) -> String {
        let template = localized(key, in: language)
        guard !args.isEmpty else { return template }
        return String(format: template, arguments: args)
    }

    func format(_ key: String, in language: AppLanguage? = nil, _ args: CVarArg...) -> String {
        format(key, in: language, args: args)
    }

    func format(_ key: String, _ args: CVarArg...) -> String {
        format(key, in: nil, args: args)
    }

    /// Locates .app/Contents/Resources/<name>.lproj or source directory fallback
    private static func findLprojBundle(named lprojName: String) -> Bundle? {
        if let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        // Direct compile-time source directory anchor
        let sourceDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Services/
            .deletingLastPathComponent() // SleepControl/
            .appendingPathComponent("Resources/\(lprojName).lproj")
        if let bundle = Bundle(url: sourceDir) {
            return bundle
        }
        // Development debug fallback path
        let devPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/SleepControl/Resources/\(lprojName).lproj")
            .path
        if let bundle = Bundle(path: devPath) {
            return bundle
        }
        return nil
    }
}

/// Convenient global localization helper
func L(_ key: String, in language: AppLanguage? = nil) -> String {
    I18n.shared.localized(key, in: language)
}

func LF(_ key: String, in language: AppLanguage? = nil, _ args: CVarArg...) -> String {
    I18n.shared.format(key, in: language, args: args)
}

func LF(_ key: String, _ args: CVarArg...) -> String {
    I18n.shared.format(key, in: nil, args: args)
}
