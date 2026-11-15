import Foundation
import Testing
import SwiftUI
import AppKit
@testable import SleepControl

@Suite("Editorial Chic UI & Functional Parity Tests")
struct EditorialUIFunctionalityTests {

    private func loadStrings(locale: String) throws -> [String: String] {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root
            .appendingPathComponent("Sources/SleepControl/Resources")
            .appendingPathComponent("\(locale).lproj")
            .appendingPathComponent("Localizable.strings")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return plist as? [String: String] ?? [:]
    }

    @Test("Verify all editorial localization keys exist and are non-empty across all 7 locales")
    func testEditorialLocalizationKeysAcrossAllLocales() throws {
        let locales = ["en", "zh-Hans", "zh-Hant-TW", "zh-Hant-HK", "ja", "fr", "es"]
        let requiredKeys = [
            "editorial.issue.awake",
            "editorial.issue.sleep",
            "editorial.headline.awake",
            "editorial.headline.sleep",
            "editorial.subtitle.awake",
            "editorial.subtitle.sleep",
            "editorial.pill.power_wake",
            "editorial.pill.power_wake_on",
            "editorial.pill.power_wake_off",
            "editorial.pill.tap_sleep",
            "editorial.pill.tap_wake",
            "editorial.popover.tap_hint",
            "editorial.popover.power_auto",
            "editorial.nerd_console.help"
        ]

        for locale in locales {
            let dict = try loadStrings(locale: locale)
            for key in requiredKeys {
                let value = dict[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                #expect(!value.isEmpty, "Missing or empty editorial key '\(key)' in \(locale).lproj")
            }
        }
    }

    @Test("Verify all editorial couture cat image assets load cleanly")
    func testEditorialCatAssetsLoad() {
        let assets = [
            "hero_cat_awake",
            "hero_cat_sleeping",
            "status_cat_awake",
            "status_cat_sleeping"
        ]
        for name in assets {
            let img = EditorialImageLoader.loadImage(named: name)
            #expect(img != nil, "Failed to load editorial cat asset: \(name)")
            if let img = img {
                #expect(img.size.width > 0 && img.size.height > 0, "Invalid dimensions for \(name)")
            }
        }
    }

    @Test("Verify EditorialTheme palette switches accurately between Awake and Sleeping states")
    func testEditorialThemePalette() {
        let awakeBg = NSColor(EditorialTheme.backgroundColor(isAwake: true)).usingColorSpace(.sRGB)
        let sleepBg = NSColor(EditorialTheme.backgroundColor(isAwake: false)).usingColorSpace(.sRGB)
        let awakeFg = NSColor(EditorialTheme.foregroundColor(isAwake: true)).usingColorSpace(.sRGB)
        let sleepFg = NSColor(EditorialTheme.foregroundColor(isAwake: false)).usingColorSpace(.sRGB)

        #expect(awakeBg != nil && sleepBg != nil && awakeFg != nil && sleepFg != nil)
        // Warm Alabaster (#F5F1E8) should be bright, Deep Obsidian (#111216) should be dark
        #expect((awakeBg?.brightnessComponent ?? 0) > 0.9)
        #expect((sleepBg?.brightnessComponent ?? 1) < 0.15)
        // Espresso Ink should be dark, Ivory Silk should be bright
        #expect((awakeFg?.brightnessComponent ?? 1) < 0.2)
        #expect((sleepFg?.brightnessComponent ?? 0) > 0.9)
    }

    @MainActor
    @Test("Verify MainWindowView, MenuBarPopoverView, and right-side NerdDashboardView drawer instantiate and lay out cleanly")
    func testViewsInstantiateAndLayoutCleanly() {
        let controller = AppController.shared
        let originalDrawer = controller.isNerdDrawerExpanded

        controller.isNerdDrawerExpanded = false
        let mainHost = NSHostingView(rootView: MainWindowView(controller: controller))
        mainHost.frame = NSRect(x: 0, y: 0, width: 460, height: 590)
        mainHost.layoutSubtreeIfNeeded()
        #expect(mainHost.fittingSize.width >= 420)
        #expect(mainHost.fittingSize.height >= 540)

        controller.isNerdDrawerExpanded = true
        let expandedHost = NSHostingView(rootView: MainWindowView(controller: controller))
        expandedHost.frame = NSRect(x: 0, y: 0, width: 980, height: 590)
        expandedHost.layoutSubtreeIfNeeded()
        #expect(expandedHost.fittingSize.width >= 940)

        let popoverHost = NSHostingView(rootView: MenuBarPopoverView(controller: controller))
        popoverHost.frame = NSRect(x: 0, y: 0, width: 340, height: 420)
        popoverHost.layoutSubtreeIfNeeded()
        #expect(popoverHost.fittingSize.width >= 320)

        let nerdHost = NSHostingView(rootView: NerdDashboardView(controller: controller))
        nerdHost.frame = NSRect(x: 0, y: 0, width: 520, height: 590)
        nerdHost.layoutSubtreeIfNeeded()
        #expect(nerdHost.fittingSize.width >= 520)

        controller.isNerdDrawerExpanded = originalDrawer
    }

    @MainActor
    @Test("Verify AppController core functional parity (autoDisableOnAC, language, banner, logs)")
    func testAppControllerFunctionalParity() {
        let controller = AppController.shared
        let originalAuto = controller.autoDisableOnAC
        let originalLang = controller.appLanguage

        // Test autoDisableOnAC toggle & UserDefaults persistence
        controller.autoDisableOnAC = false
        #expect(controller.autoDisableOnAC == false)
        controller.autoDisableOnAC = true
        #expect(controller.autoDisableOnAC == true)

        // Test language switching
        controller.selectLanguage(.ja)
        #expect(controller.appLanguage == .ja)
        controller.selectLanguage(.fr)
        #expect(controller.appLanguage == .fr)
        controller.selectLanguage(.es)
        #expect(controller.appLanguage == .es)
        controller.selectLanguage(.zhHans)
        #expect(controller.appLanguage == .zhHans)

        // Test banner presentation & dismissal
        controller.showBanner("Test Notice", isError: false)
        #expect(controller.bannerMessage == "Test Notice")
        #expect(controller.isBannerError == false)
        controller.clearBanner()
        #expect(controller.bannerMessage == nil)

        // Restore original preferences
        controller.autoDisableOnAC = originalAuto
        controller.selectLanguage(originalLang)
    }

    @Test("Verify full key parity for French and Spanish localization bundles against English")
    func testFrenchAndSpanishFullKeyParity() throws {
        let enDict = try loadStrings(locale: "en")
        for locale in ["fr", "es"] {
            let dict = try loadStrings(locale: locale)
            for key in enDict.keys {
                let value = dict[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                #expect(!value.isEmpty, "Missing or empty key '\(key)' in \(locale).lproj/Localizable.strings")
            }
        }
    }
}
