import Foundation
import Testing
@testable import SleepControl

@Suite("Application Version Resolution & Localization Tests")
struct AppVersionTests {

    private let supportedLanguages: [AppLanguage] = [
        .en,
        .zhHans,
        .zhHantTW,
        .zhHantHK,
        .ja
    ]

    // MARK: - Core Version Resolution Tests

    @Test("Verify raw marketing version returns non-empty valid string")
    func testRawVersionReturnsValidString() {
        let raw = AppVersion.raw()
        #expect(!raw.isEmpty)
        #expect(!raw.hasPrefix("v"))
        #expect(!raw.hasPrefix("V"))
        #expect(raw.contains("."))
    }

    @Test("Verify formatted version displays with 'v' prefix without duplication")
    func testFormattedVersionPrefix() {
        let formatted = AppVersion.formatted()
        #expect(formatted.hasPrefix("v"))
        #expect(!formatted.hasPrefix("vv"))
        #expect(!formatted.hasPrefix("vV"))
        #expect(formatted.count >= 4) // e.g. "v1.0"
        #expect(formatted == "v\(AppVersion.raw())")
    }

    @Test("Verify safe fallback to static constant when bundle is empty and dev bundle disabled")
    func testFallbackOnEmptyBundle() {
        let emptyBundle = Bundle()
        let rawFallback = AppVersion.raw(bundle: emptyBundle, checkDevBundle: false)
        #expect(rawFallback == AppVersion.fallbackVersion)

        let formattedFallback = AppVersion.formatted(bundle: emptyBundle, checkDevBundle: false)
        #expect(formattedFallback == "v\(AppVersion.fallbackVersion)")
    }

    @Test("Verify static fallback version constant is valid release format")
    func testStaticFallbackVersionConstant() {
        #expect(AppVersion.fallbackVersion == "1.1.2")
    }

    // MARK: - AppController Integration Tests

    @Test("Verify AppController convenience version properties match AppVersion utility")
    @MainActor
    func testAppControllerVersionProperties() {
        let controller = AppController.shared
        #expect(controller.appVersionString == AppVersion.raw())
        #expect(controller.appVersionDisplayString == AppVersion.formatted())
    }

    // MARK: - Localization String Tests

    @Test("Verify dashboard.version key resolves correctly across all 5 supported locales")
    func testDashboardVersionLocalizationAcrossAllLocales() {
        let sampleVersion = "1.1.2"
        for lang in supportedLanguages {
            let localizedPattern = I18n.shared.localized("dashboard.version", in: lang)
            #expect(localizedPattern == "v%@", "Failed for language: \(lang.rawValue)")

            let formattedString = LF("dashboard.version", in: lang, sampleVersion)
            #expect(formattedString == "v1.1.2", "Failed formatting for language: \(lang.rawValue)")

            let dynamicFormatted = LF("dashboard.version", in: lang, AppVersion.raw())
            #expect(dynamicFormatted == AppVersion.formatted(), "Dynamic formatted mismatch for language: \(lang.rawValue)")
        }
    }
}
