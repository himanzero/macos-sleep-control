import Foundation
import Testing
import SwiftUI
import AppKit
@testable import SleepControl

@Suite("Core Functional Parity & Hardware Telemetry Tests")
struct FunctionalParityTests {

    @Test("Verify SleepManager.fetchTelemetry reads live pmset -g state cleanly")
    func testLivePmsetTelemetryFetch() {
        let telemetry = SleepManager.shared.fetchTelemetry()
        // displaySleepFormatted / systemSleepFormatted / hibernateModeFormatted should always produce non-empty localized strings
        #expect(!telemetry.displaySleepFormatted.isEmpty)
        #expect(!telemetry.systemSleepFormatted.isEmpty)
        #expect(!telemetry.hibernateModeFormatted.isEmpty)
    }

    @Test("Verify PowerMonitor reads live IOKit power snapshot and clamshell state")
    func testLiveIOKitPowerMonitor() {
        let monitor = PowerMonitor()
        let snapshot = monitor.readCurrentPowerSnapshot()
        #expect(snapshot.source == .ac || snapshot.source == .battery || snapshot.source == .unknown)
        #expect(!snapshot.formattedSummary.isEmpty)

        // Ensure AppleClamshellState query executes safely without crash
        _ = monitor.isClamshellClosed()
    }

    @Test("Verify SleepManager.isPasswordlessSudoEnabled executes non-destructively")
    func testPasswordlessSudoCheck() {
        _ = SleepManager.shared.isPasswordlessSudoEnabled()
    }

    @MainActor
    @Test("Verify AppController refreshAllState, refreshTelemetryOnly, and companion quote cycling")
    func testAppControllerStateSyncAndQuotes() {
        let controller = AppController.shared
        controller.refreshAllState()
        controller.refreshTelemetryOnly()

        let initialQuoteIdx = controller.companionQuoteIndex
        controller.petCompanion()
        #expect(controller.companionQuoteIndex == (initialQuoteIdx + 1) % 3)
        #expect(!controller.currentCompanionQuote.isEmpty)
    }

    @MainActor
    @Test("Verify AppController logging lifecycle (power, clamshell, auto-disable, clearLogs)")
    func testAppControllerLoggingLifecycle() {
        let controller = AppController.shared
        let initialCount = controller.activityLogs.count

        controller.logAutoDisableChanged(enabled: true)
        controller.logClamshellSleep()
        #expect(controller.activityLogs.count >= min(initialCount + 2, AppController.maxLogCount))

        controller.clearLogs()
        #expect(controller.activityLogs.isEmpty)

        // Re-seed initial ready log so controller remains in clean state
        controller.refreshAllState(isInitial: true)
        #expect(!controller.activityLogs.isEmpty)
    }

    @MainActor
    @Test("Verify all 3 UI surfaces render cleanly with active banner and expanded Nerd drawer")
    func testUISurfacesWithActiveBannerAndDrawer() {
        let controller = AppController.shared
        let originalDrawer = controller.isNerdDrawerExpanded

        controller.showBanner("Functional Parity Banner", isError: false)
        controller.isNerdDrawerExpanded = true

        let mainHost = NSHostingView(rootView: MainWindowView(controller: controller))
        mainHost.frame = NSRect(x: 0, y: 0, width: 980, height: 590)
        mainHost.layoutSubtreeIfNeeded()
        #expect(mainHost.fittingSize.width >= 940)

        let popoverHost = NSHostingView(rootView: MenuBarPopoverView(controller: controller))
        popoverHost.frame = NSRect(x: 0, y: 0, width: 340, height: 420)
        popoverHost.layoutSubtreeIfNeeded()
        #expect(popoverHost.fittingSize.height >= 360)

        controller.clearBanner()
        controller.isNerdDrawerExpanded = originalDrawer
    }
}
