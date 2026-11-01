import Foundation
import SwiftUI
import ServiceManagement

/// Global state and automation coordinator
@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    /// Indicates whether system sleep is currently disabled (`SleepDisabled == 1`)
    @Published private(set) var isSleepDisabled: Bool = false
    /// Low-level pmset telemetry snapshot
    @Published private(set) var telemetry: PmsetTelemetry = PmsetTelemetry()
    /// Real-time power source and battery snapshot
    @Published private(set) var powerSnapshot: PowerSnapshot = PowerSnapshot()
    /// Indicates whether passwordless sudoers is configured
    @Published private(set) var isPasswordlessConfigured: Bool = false
    /// Indicates whether an asynchronous operation is in progress
    @Published private(set) var isBusy: Bool = false
    /// Notification banner message
    @Published var bannerMessage: String? = nil
    @Published var isBannerError: Bool = false
    /// Launch at login status
    @Published private(set) var launchAtLoginEnabled: Bool = false
    /// Recent activity log items
    @Published private(set) var activityLogs: [ActivityLogItem] = []
    /// Active companion quote index (0...2) cycled when petting the cat
    @Published private(set) var companionQuoteIndex: Int = 0
    /// Transient bounce state when user pets the companion cat
    @Published private(set) var isPetBouncing: Bool = false
    /// Transient floating heart badge when user pets the companion cat
    @Published private(set) var showPetHeart: Bool = false

    /// Active interface language (defaults to system `.system`, falls back to `.en`)
    @Published var appLanguage: AppLanguage {
        didSet {
            I18n.shared.setLanguage(appLanguage)
            objectWillChange.send()
        }
    }

    /// Automatically disable sleep on AC power, and restore sleep on battery
    @Published var autoDisableOnAC: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableOnAC, forKey: Self.autoDisableKey)
            if !isInitializing {
                handleAutoDisableSettingChanged()
            }
        }
    }

    private static let autoDisableKey = "com.himanzero.SleepControl.autoDisableOnAC"
    private let sleepManager = SleepManager.shared
    private let powerMonitor = PowerMonitor()
    private var refreshTimer: Timer?
    private var lastPowerSource: PowerSourceKind = .unknown
    private var isInitializing: Bool = true

    init() {
        let savedAuto = UserDefaults.standard.object(forKey: Self.autoDisableKey) as? Bool ?? true
        self.autoDisableOnAC = savedAuto
        self.appLanguage = I18n.shared.currentLanguage

        // Initial state synchronization
        refreshAllState(isInitial: true)
        isInitializing = false

        // Start IOKit real-time power event monitoring
        powerMonitor.startMonitoring { [weak self] newSnapshot in
            Task { @MainActor [weak self] in
                self?.handlePowerSnapshotUpdate(newSnapshot)
            }
        }

        // Periodic telemetry synchronization (every 4 seconds) to detect CLI script changes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.silentSyncTelemetry()
            }
        }

        // Align sleep state with power source on app launch if enabled and passwordless auth is ready
        if autoDisableOnAC && isPasswordlessConfigured {
            reconcileSleepWithCurrentPower(reason: L("msg.reason.startup_sync"))
        }
    }

    // MARK: - Language Switching

    func selectLanguage(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.appLanguage = language
        }
    }

    // MARK: - State Refresh

    func refreshAllState(isInitial: Bool = false) {
        let currentTelemetry = sleepManager.fetchTelemetry()
        let currentPower = powerMonitor.readCurrentPowerSnapshot()
        let passwordless = sleepManager.isPasswordlessSudoEnabled()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.telemetry = currentTelemetry
            self.isSleepDisabled = currentTelemetry.isSleepDisabled
            self.powerSnapshot = currentPower
            self.isPasswordlessConfigured = passwordless
            self.launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }

        if isInitial {
            self.lastPowerSource = currentPower.source
            let stateText = currentTelemetry.isSleepDisabled
                ? L("telemetry.val.disabled")
                : L("telemetry.val.enabled")
            appendLog(
                title: L("msg.ready.title"),
                detail: LF("msg.ready.detail", stateText, currentPower.formattedSummary),
                isSuccess: true,
                isAutomated: true
            )
        }
    }

    private func silentSyncTelemetry() {
        guard !isBusy else { return }
        let latest = sleepManager.fetchTelemetry()
        let latestPower = powerMonitor.readCurrentPowerSnapshot()
        let passwordless = sleepManager.isPasswordlessSudoEnabled()

        if latest.isSleepDisabled != self.isSleepDisabled {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.isSleepDisabled = latest.isSleepDisabled
            }
            let stateText = latest.isSleepDisabled
                ? L("telemetry.val.disabled")
                : L("telemetry.val.enabled")
            appendLog(
                title: L("msg.external_change.title"),
                detail: LF("msg.external_change.detail", stateText),
                isSuccess: true,
                isAutomated: true
            )
        }
        self.telemetry = latest
        self.powerSnapshot = latestPower
        self.isPasswordlessConfigured = passwordless
    }

    // MARK: - Manual Sleep Toggling

    func toggleSleepDisabled() {
        setSleepDisabled(!isSleepDisabled, isAutomated: false, reason: L("msg.reason.manual"))
    }

    func setSleepDisabled(_ targetDisable: Bool, isAutomated: Bool, reason: String) {
        guard !isBusy else { return }
        isBusy = true
        clearBanner()

        let allowInteractive = !isAutomated || isPasswordlessConfigured
        let manager = self.sleepManager

        Task.detached(priority: .userInitiated) {
            let result = manager.setSleepDisabled(targetDisable, allowInteractiveAuth: allowInteractive)
            let updatedTelemetry = manager.fetchTelemetry()
            let passwordless = manager.isPasswordlessSudoEnabled()

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isBusy = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    self.telemetry = updatedTelemetry
                    self.isSleepDisabled = updatedTelemetry.isSleepDisabled
                    self.isPasswordlessConfigured = passwordless
                }

                switch result {
                case .success:
                    let actionDesc = targetDisable ? L("msg.toggle.disabled") : L("msg.toggle.enabled")
                    self.appendLog(
                        title: actionDesc,
                        detail: LF("msg.toggle.source", reason),
                        isSuccess: true,
                        isAutomated: isAutomated
                    )
                case .failure(let error):
                    if case SleepControlError.userCanceledAuth = error {
                        self.showBanner(L("msg.auth.canceled"), isError: false)
                    } else {
                        self.showBanner(error.localizedDescription, isError: true)
                    }
                    self.appendLog(
                        title: L("msg.toggle.failed"),
                        detail: "\(reason) — \(error.localizedDescription)",
                        isSuccess: false,
                        isAutomated: isAutomated
                    )
                }
            }
        }
    }

    // MARK: - Power Transition Handling

    private func handlePowerSnapshotUpdate(_ newSnapshot: PowerSnapshot) {
        let previousSource = self.lastPowerSource
        self.powerSnapshot = newSnapshot
        self.lastPowerSource = newSnapshot.source

        guard previousSource != .unknown,
              newSnapshot.source != .unknown,
              previousSource != newSnapshot.source else {
            return
        }

        let sourceEventTitle = (newSnapshot.source == .ac)
            ? L("msg.power.ac_connected")
            : L("msg.power.battery_switched")
        appendLog(
            title: sourceEventTitle,
            detail: newSnapshot.formattedSummary,
            isSuccess: true,
            isAutomated: true
        )

        guard autoDisableOnAC else { return }
        let companionBanner = (newSnapshot.source == .ac)
            ? L("msg.power.ac_companion_banner")
            : L("msg.power.battery_companion_banner")
        showBanner(companionBanner, isError: false)
        reconcileSleepWithCurrentPower(reason: sourceEventTitle)
    }

    private func handleAutoDisableSettingChanged() {
        if autoDisableOnAC {
            appendLog(
                title: L("msg.auto.turned_on.title"),
                detail: L("msg.auto.turned_on.detail"),
                isSuccess: true,
                isAutomated: false
            )
            reconcileSleepWithCurrentPower(reason: L("msg.reason.auto_enabled"))
        } else {
            appendLog(
                title: L("msg.auto.turned_off.title"),
                detail: L("msg.auto.turned_off.detail"),
                isSuccess: true,
                isAutomated: false
            )
        }
    }

    /// Aligns `disablesleep` state according to current power source
    private func reconcileSleepWithCurrentPower(reason: String) {
        let currentSource = powerSnapshot.source
        guard currentSource == .ac || currentSource == .battery else { return }

        let shouldDisableSleep = (currentSource == .ac)
        if isSleepDisabled != shouldDisableSleep {
            setSleepDisabled(shouldDisableSleep, isAutomated: true, reason: reason)
        }
    }

    // MARK: - Passwordless Sudoers Setup and Revocation

    func configurePasswordlessSudo() {
        guard !isBusy else { return }
        isBusy = true
        clearBanner()
        let manager = self.sleepManager

        Task.detached(priority: .userInitiated) {
            let result = manager.configurePasswordlessSudo()
            let passwordless = manager.isPasswordlessSudoEnabled()

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isBusy = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.isPasswordlessConfigured = passwordless
                }

                switch result {
                case .success:
                    self.showBanner(L("msg.auth.enabled.banner"), isError: false)
                    self.appendLog(
                        title: L("msg.auth.enabled.title"),
                        detail: L("msg.auth.enabled.detail"),
                        isSuccess: true,
                        isAutomated: false
                    )
                    if self.autoDisableOnAC {
                        self.reconcileSleepWithCurrentPower(reason: L("msg.reason.auth_done_sync"))
                    }
                case .failure(let error):
                    if case SleepControlError.userCanceledAuth = error {
                        self.showBanner(L("msg.auth.canceled"), isError: false)
                    } else {
                        self.showBanner(error.localizedDescription, isError: true)
                    }
                }
            }
        }
    }

    func revokePasswordlessSudo() {
        guard !isBusy else { return }
        isBusy = true
        clearBanner()
        let manager = self.sleepManager

        Task.detached(priority: .userInitiated) {
            let result = manager.removePasswordlessSudo()
            let passwordless = manager.isPasswordlessSudoEnabled()

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isBusy = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.isPasswordlessConfigured = passwordless
                }
                if case .success = result {
                    self.showBanner(L("msg.auth.revoked.banner"), isError: false)
                    self.appendLog(
                        title: L("msg.auth.revoked.title"),
                        detail: L("msg.auth.revoked.detail"),
                        isSuccess: true,
                        isAutomated: false
                    )
                }
            }
        }
    }

    // MARK: - Launch at Login

    func toggleLaunchAtLogin() {
        do {
            if launchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
            appendLog(
                title: launchAtLoginEnabled ? L("msg.launch.on") : L("msg.launch.off"),
                detail: L("msg.launch.detail"),
                isSuccess: true,
                isAutomated: false
            )
        } catch {
            showBanner(LF("msg.launch.error", error.localizedDescription), isError: true)
        }
    }

    // MARK: - Helper Methods

    /// Cycles the companion cat quote and triggers a playful bounce/heart micro-animation
    func petCompanion() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            companionQuoteIndex = (companionQuoteIndex + 1) % 3
            isPetBouncing = true
            showPetHeart = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { [weak self] in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                self?.isPetBouncing = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.showPetHeart = false
            }
        }
    }

    /// Returns the localized companion dialogue line for the current state and quote index
    var currentCompanionQuote: String {
        let prefix = isSleepDisabled ? "companion.quote.awake" : "companion.quote.sleep"
        return L("\(prefix).\(companionQuoteIndex % 3)")
    }

    func showBanner(_ message: String, isError: Bool) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.bannerMessage = message
            self.isBannerError = isError
        }
    }

    func clearBanner() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.bannerMessage = nil
        }
    }

    func clearLogs() {
        withAnimation {
            self.activityLogs.removeAll()
        }
    }

    private func appendLog(title: String, detail: String, isSuccess: Bool, isAutomated: Bool) {
        let item = ActivityLogItem(
            timestamp: Date(),
            title: title,
            detail: detail,
            isSuccess: isSuccess,
            isAutomated: isAutomated
        )
        self.activityLogs.insert(item, at: 0)
        if self.activityLogs.count > 30 {
            self.activityLogs.removeLast(self.activityLogs.count - 30)
        }
    }
}
