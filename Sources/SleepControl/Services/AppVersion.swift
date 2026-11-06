import Foundation

/// Application version resolution utility with dynamic bundle detection and safe tiered fallbacks
public enum AppVersion {
    /// Baseline fallback version matching the current release cycle
    public static let fallbackVersion = "1.1.2"

    /// Resolves the raw marketing version string (e.g., "1.1.2")
    public static func raw(bundle: Bundle = .main, checkDevBundle: Bool = true) -> String {
        // 1. Primary: Read CFBundleShortVersionString from the provided bundle (production .app)
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return stripVPrefix(trimmed)
            }
        }

        // 2. Secondary: If running unbundled in dev environment, inspect adjacent SleepControl.app
        if checkDevBundle,
           let devBundle = Bundle(path: "SleepControl.app"),
           let version = devBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return stripVPrefix(trimmed)
            }
        }

        // 3. Tertiary: Static compile-time safety fallback
        return fallbackVersion
    }

    /// Resolves the formatted version display string with a "v" prefix (e.g., "v1.1.2")
    public static func formatted(bundle: Bundle = .main, checkDevBundle: Bool = true) -> String {
        let rawVersion = raw(bundle: bundle, checkDevBundle: checkDevBundle)
        if rawVersion.hasPrefix("v") || rawVersion.hasPrefix("V") {
            return rawVersion
        }
        return "v\(rawVersion)"
    }

    /// Strips leading 'v' or 'V' prefix to ensure raw version consistency
    private static func stripVPrefix(_ version: String) -> String {
        if version.hasPrefix("v") || version.hasPrefix("V") {
            return String(version.dropFirst())
        }
        return version
    }
}
