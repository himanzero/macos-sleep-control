import Foundation
import Testing
@testable import SleepControl

@Suite("Activity Log Localization & Retention Tests")
struct ActivityLogTests {

    private let supportedLanguages: [AppLanguage] = [
        .en,
        .zhHans,
        .zhHantTW,
        .zhHantHK,
        .ja
    ]

    // MARK: - R1 & AC: Per-locale Resolution of Activity Log Titles and Details

    @Test("Verify activity log items resolve to expected localized text in all supported locales")
    func testAllSupportedLocalesResolution() {
        let snapshotAC = PowerSnapshot(source: .ac, batteryPercentage: 100, isCharging: false, isCharged: true)
        let snapshotBattery = PowerSnapshot(source: .battery, batteryPercentage: 75, isCharging: false, isCharged: false)

        for lang in supportedLanguages {
            // 1. Ready event
            let readyItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.ready.title",
                titleArgs: [],
                detailKey: "msg.ready.detail",
                detailArgs: [
                    .sleepState(isSleepDisabled: true),
                    .powerSnapshot(snapshotAC)
                ],
                isSuccess: true,
                isAutomated: true
            )

            let expectedReadyTitle = I18n.shared.localized("msg.ready.title", in: lang)
            let readyTitle = readyItem.localizedTitle(in: lang)
            #expect(readyTitle == expectedReadyTitle)
            #expect(!readyTitle.isEmpty)

            let readyDetail = readyItem.localizedDetail(in: lang)
            #expect(!readyDetail.isEmpty)
            #expect(readyDetail.contains(I18n.shared.localized("telemetry.val.disabled", in: lang)))
            #expect(readyDetail.contains(snapshotAC.source.localizedDisplayName(in: lang)))

            // 2. External change event
            let extChangeItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.external_change.title",
                titleArgs: [],
                detailKey: "msg.external_change.detail",
                detailArgs: [.sleepState(isSleepDisabled: false)],
                isSuccess: true,
                isAutomated: true
            )
            let extTitle = extChangeItem.localizedTitle(in: lang)
            let extDetail = extChangeItem.localizedDetail(in: lang)
            #expect(extTitle == I18n.shared.localized("msg.external_change.title", in: lang))
            #expect(extDetail.contains(I18n.shared.localized("telemetry.val.enabled", in: lang)))

            // 3. Toggle success event
            let toggleSuccessItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.toggle.disabled",
                titleArgs: [],
                detailKey: "msg.toggle.source",
                detailArgs: [.localizedKey("msg.reason.manual")],
                isSuccess: true,
                isAutomated: false
            )
            let toggleTitle = toggleSuccessItem.localizedTitle(in: lang)
            let toggleDetail = toggleSuccessItem.localizedDetail(in: lang)
            #expect(toggleTitle == I18n.shared.localized("msg.toggle.disabled", in: lang))
            #expect(toggleDetail.contains(I18n.shared.localized("msg.reason.manual", in: lang)))

            // 4. Toggle failure event
            let toggleFailureItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.toggle.failed",
                titleArgs: [],
                detailKey: nil,
                detailArgs: [
                    .localizedKey("msg.reason.hero_switch"),
                    .error(SleepControlError.userCanceledAuth)
                ],
                customDetailFormat: "%@ — %@",
                isSuccess: false,
                isAutomated: false
            )
            let failTitle = toggleFailureItem.localizedTitle(in: lang)
            let failDetail = toggleFailureItem.localizedDetail(in: lang)
            #expect(failTitle == I18n.shared.localized("msg.toggle.failed", in: lang))
            #expect(failDetail.contains(I18n.shared.localized("msg.reason.hero_switch", in: lang)))
            #expect(failDetail.contains(I18n.shared.localized("err.user_canceled", in: lang)))

            // 5. Power transition event
            let powerItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.power.battery_switched",
                titleArgs: [],
                detailKey: nil,
                detailArgs: [.powerSnapshot(snapshotBattery)],
                customDetailFormat: "%@",
                isSuccess: true,
                isAutomated: true
            )
            let powerTitle = powerItem.localizedTitle(in: lang)
            let powerDetail = powerItem.localizedDetail(in: lang)
            #expect(powerTitle == I18n.shared.localized("msg.power.battery_switched", in: lang))
            #expect(powerDetail.contains(snapshotBattery.source.localizedDisplayName(in: lang)))
            #expect(powerDetail.contains("75%"))

            // 6. Automation turned on / off
            let autoOnItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.auto.turned_on.title",
                titleArgs: [],
                detailKey: "msg.auto.turned_on.detail",
                detailArgs: [],
                isSuccess: true,
                isAutomated: false
            )
            #expect(autoOnItem.localizedTitle(in: lang) == I18n.shared.localized("msg.auto.turned_on.title", in: lang))
            #expect(autoOnItem.localizedDetail(in: lang) == I18n.shared.localized("msg.auto.turned_on.detail", in: lang))

            // 7. Passwordless auth enabled / revoked
            let authOnItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.auth.enabled.title",
                titleArgs: [],
                detailKey: "msg.auth.enabled.detail",
                detailArgs: [],
                isSuccess: true,
                isAutomated: false
            )
            #expect(authOnItem.localizedTitle(in: lang) == I18n.shared.localized("msg.auth.enabled.title", in: lang))
            #expect(authOnItem.localizedDetail(in: lang) == I18n.shared.localized("msg.auth.enabled.detail", in: lang))

            // 8. Launch at login
            let launchItem = ActivityLogItem(
                timestamp: Date(),
                titleKey: "msg.launch.on",
                titleArgs: [],
                detailKey: "msg.launch.detail",
                detailArgs: [],
                isSuccess: true,
                isAutomated: false
            )
            #expect(launchItem.localizedTitle(in: lang) == I18n.shared.localized("msg.launch.on", in: lang))
            #expect(launchItem.localizedDetail(in: lang) == I18n.shared.localized("msg.launch.detail", in: lang))
        }
    }

    // MARK: - R1 & AC: Dynamic Hot-Switching of Existing Log Entries

    @Test("Verify language switching dynamically updates existing activity logs without restart or data loss")
    @MainActor
    func testDynamicLanguageSwitchingOnExistingLogs() {
        let initialLang = I18n.shared.currentLanguage
        defer {
            I18n.shared.setLanguage(initialLang)
        }

        let controller = AppController.shared
        controller.clearLogs()

        let powerSnapshot = PowerSnapshot(source: .ac, batteryPercentage: 92, isCharging: true, isCharged: false)

        // Populate controller with several log items
        controller.logReady(isSleepDisabled: true, powerSnapshot: powerSnapshot)
        controller.logToggleSuccess(targetDisable: true, reasonKey: "msg.reason.manual", isAutomated: false)
        controller.logToggleFailure(reasonKey: "msg.reason.hero_switch", error: SleepControlError.passwordlessNotConfigured, isAutomated: false)
        controller.logToggleFailure(reasonKey: "msg.reason.startup_sync", error: SleepControlError.executionFailedWithCode(42), isAutomated: true)
        controller.logPowerTransition(newSnapshot: powerSnapshot)

        #expect(controller.activityLogs.count == 5)

        // Capture item identities and flags to verify zero data loss
        let originalIds = controller.activityLogs.map { $0.id }
        let originalSuccessFlags = controller.activityLogs.map { $0.isSuccess }
        let originalAutomatedFlags = controller.activityLogs.map { $0.isAutomated }

        // Test English
        controller.selectLanguage(.en)
        #expect(controller.activityLogs[4].title == "System Status Ready")
        #expect(controller.activityLogs[4].detail.contains("1 (Sleep Disabled)"))
        #expect(controller.activityLogs[4].detail.contains("AC Power"))
        #expect(controller.activityLogs[3].title == "System Sleep Disabled (disablesleep 1)")
        #expect(controller.activityLogs[3].detail.contains("Manual toggle"))
        #expect(controller.activityLogs[2].title == "Sleep Toggle Incomplete")
        #expect(controller.activityLogs[2].detail.contains("Passwordless auth is not enabled yet"))
        #expect(controller.activityLogs[1].title == "Sleep Toggle Incomplete")
        #expect(controller.activityLogs[1].detail.contains("Privileged command failed (exit code 42)"))
        #expect(controller.activityLogs[0].title == "AC Power Connected")

        // Switch to Simplified Chinese
        controller.selectLanguage(.zhHans)
        #expect(controller.activityLogs[4].title == "系统状态已就绪")
        #expect(controller.activityLogs[4].detail.contains("1 (已禁止休眠)"))
        #expect(controller.activityLogs[4].detail.contains("交流电源 (AC)"))
        #expect(controller.activityLogs[3].title == "已禁止系统休眠 (disablesleep 1)")
        #expect(controller.activityLogs[3].detail.contains("手动切换开关"))
        #expect(controller.activityLogs[2].title == "切换休眠状态未完成")
        #expect(controller.activityLogs[2].detail.contains("尚未开启免密授权"))
        #expect(controller.activityLogs[1].title == "切换休眠状态未完成")
        #expect(controller.activityLogs[1].detail.contains("授权命令执行失败 (退出码 42)"))
        #expect(controller.activityLogs[0].title == "检测到接入交流电源 (AC)")

        // Switch to Japanese
        controller.selectLanguage(.ja)
        #expect(controller.activityLogs[4].title == "システム準備完了")
        #expect(controller.activityLogs[4].detail.contains("1 (スリープ禁止中)"))
        #expect(controller.activityLogs[4].detail.contains("AC電源"))
        #expect(controller.activityLogs[3].title == "システムスリープを禁止しました (disablesleep 1)")
        #expect(controller.activityLogs[3].detail.contains("手動スイッチ切り替え"))
        #expect(controller.activityLogs[2].title == "スリープ状態の切り替え未完了")
        #expect(controller.activityLogs[2].detail.contains("パスワードなし認証が未設定です"))
        #expect(controller.activityLogs[1].title == "スリープ状態の切り替え未完了")
        #expect(controller.activityLogs[1].detail.contains("特権コマンドの実行に失敗しました (終了コード 42)"))
        #expect(controller.activityLogs[0].title == "AC電源の接続を検出")

        // Switch to Traditional Chinese (Taiwan)
        controller.selectLanguage(.zhHantTW)
        #expect(controller.activityLogs[4].title == "系統狀態已就緒")
        #expect(controller.activityLogs[4].detail.contains("1 (已禁止休眠)"))
        #expect(controller.activityLogs[4].detail.contains("交流電源 (AC)"))
        #expect(controller.activityLogs[3].title == "已禁止系統休眠 (disablesleep 1)")
        #expect(controller.activityLogs[3].detail.contains("手動切換開關"))
        #expect(controller.activityLogs[2].title == "切換休眠狀態未完成")
        #expect(controller.activityLogs[2].detail.contains("尚未開啟免密授權"))
        #expect(controller.activityLogs[1].title == "切換休眠狀態未完成")
        #expect(controller.activityLogs[1].detail.contains("授權指令執行失敗 (結束碼 42)"))
        #expect(controller.activityLogs[0].title == "偵測到接上交流電源 (AC)")

        // Switch to Traditional Chinese (Hong Kong)
        controller.selectLanguage(.zhHantHK)
        #expect(controller.activityLogs[4].title == "系統狀態已就緒")
        #expect(controller.activityLogs[4].detail.contains("1 (已禁止休眠)"))
        #expect(controller.activityLogs[4].detail.contains("交流電源 (AC)"))
        #expect(controller.activityLogs[3].title == "已禁止系統休眠 (disablesleep 1)")
        #expect(controller.activityLogs[3].detail.contains("手動切換開關"))
        #expect(controller.activityLogs[2].title == "切換休眠狀態未完成")
        #expect(controller.activityLogs[2].detail.contains("尚未開啟免密授權"))
        #expect(controller.activityLogs[1].title == "切換休眠狀態未完成")
        #expect(controller.activityLogs[1].detail.contains("授權指令執行失敗 (結束碼 42)"))
        #expect(controller.activityLogs[0].title == "偵測到接駁交流電源 (AC)")

        // Switch to Follow System
        controller.selectLanguage(.system)
        #expect(!controller.activityLogs[4].title.isEmpty)
        #expect(!controller.activityLogs[4].detail.isEmpty)
        #expect(!controller.activityLogs[1].detail.isEmpty)

        // Verify metadata integrity (no ID loss, order maintained, status flags intact)
        #expect(controller.activityLogs.map { $0.id } == originalIds)
        #expect(controller.activityLogs.map { $0.isSuccess } == originalSuccessFlags)
        #expect(controller.activityLogs.map { $0.isAutomated } == originalAutomatedFlags)
    }

    // MARK: - R1 & AC: Log Message Parameter Localization

    @Test("Verify log parameters (power sources, sleep states, error descriptions) are localized according to active language")
    func testLogParametersLocalization() {
        // Power source kinds
        for lang in supportedLanguages {
            let acName = PowerSourceKind.ac.localizedDisplayName(in: lang)
            let battName = PowerSourceKind.battery.localizedDisplayName(in: lang)
            let unknownName = PowerSourceKind.unknown.localizedDisplayName(in: lang)

            #expect(!acName.isEmpty)
            #expect(!battName.isEmpty)
            #expect(!unknownName.isEmpty)

            switch lang {
            case .en:
                #expect(acName == "AC Power")
                #expect(battName == "Battery Power")
            case .zhHans:
                #expect(acName == "交流电源 (AC)")
                #expect(battName == "电池供电")
            case .ja:
                #expect(acName == "AC電源")
                #expect(battName == "バッテリー電源")
            case .zhHantTW, .zhHantHK:
                #expect(acName == "交流電源 (AC)")
                #expect(battName == "電池供電")
            case .system:
                break
            }

            // Sleep state values
            let disabledState = ActivityLogParameter.sleepState(isSleepDisabled: true).resolve(in: lang)
            let enabledState = ActivityLogParameter.sleepState(isSleepDisabled: false).resolve(in: lang)
            #expect(!disabledState.isEmpty)
            #expect(!enabledState.isEmpty)

            switch lang {
            case .en:
                #expect(disabledState == "1 (Sleep Disabled)")
                #expect(enabledState == "0 (Sleep Allowed)")
            case .zhHans, .zhHantTW, .zhHantHK:
                #expect(disabledState.contains("已禁止休眠"))
                #expect(enabledState.contains("允许") || enabledState.contains("允許"))
            case .ja:
                #expect(disabledState == "1 (スリープ禁止中)")
                #expect(enabledState == "0 (通常スリープ許可)")
            case .system:
                break
            }

            // Error descriptions
            let errNotConfigured = SleepControlError.passwordlessNotConfigured.localizedErrorDescription(in: lang)
            let errCanceled = SleepControlError.userCanceledAuth.localizedErrorDescription(in: lang)
            let errInvalidUser = SleepControlError.invalidUsername("tester").localizedErrorDescription(in: lang)
            let errExecFailed = SleepControlError.executionFailed("Code 127").localizedErrorDescription(in: lang)
            let errExecFailedWithCode = SleepControlError.executionFailedWithCode(127).localizedErrorDescription(in: lang)

            #expect(!errNotConfigured.isEmpty)
            #expect(!errCanceled.isEmpty)
            #expect(!errInvalidUser.isEmpty)
            #expect(errInvalidUser.contains("tester"))
            #expect(errExecFailed == "Code 127")
            #expect(!errExecFailedWithCode.isEmpty)
            #expect(errExecFailedWithCode.contains("127"))
        }
    }

    // MARK: - R3: Localization Strings Files Integrity

    @Test("Verify all activity log localization keys exist and are non-empty across all 5 .lproj files")
    func testLocalizationStringsFilesIntegrity() throws {
        let requiredKeys: [String] = [
            "msg.ready.title",
            "msg.ready.detail",
            "msg.external_change.title",
            "msg.external_change.detail",
            "msg.toggle.disabled",
            "msg.toggle.enabled",
            "msg.toggle.source",
            "msg.toggle.failed",
            "msg.reason.manual",
            "msg.reason.hero_switch",
            "msg.reason.startup_sync",
            "msg.reason.auto_enabled",
            "msg.reason.auth_done_sync",
            "msg.power.ac_connected",
            "msg.power.battery_switched",
            "msg.power.ac_companion_banner",
            "msg.power.battery_companion_banner",
            "msg.auto.turned_on.title",
            "msg.auto.turned_on.detail",
            "msg.auto.turned_off.title",
            "msg.auto.turned_off.detail",
            "msg.auth.canceled",
            "msg.auth.enabled.banner",
            "msg.auth.enabled.title",
            "msg.auth.enabled.detail",
            "msg.auth.revoked.banner",
            "msg.auth.revoked.title",
            "msg.auth.revoked.detail",
            "msg.launch.on",
            "msg.launch.off",
            "msg.launch.detail",
            "msg.launch.error",
            "err.passwordless_not_configured",
            "err.user_canceled",
            "err.invalid_username",
            "err.exec_failed",
            "power.source.ac",
            "power.source.battery",
            "power.source.unknown",
            "power.status.charging",
            "power.status.charged",
            "power.status.external",
            "power.summary.ac",
            "power.summary.battery",
            "telemetry.val.disabled",
            "telemetry.val.enabled"
        ]

        let lprojFolders = ["en", "zh-Hans", "zh-Hant-TW", "zh-Hant-HK", "ja"]

        for folder in lprojFolders {
            guard let lang = AppLanguage(rawValue: folder),
                  let bundle = I18n.shared.bundle(for: lang) else {
                Issue.record("Missing bundle for language: \(folder)")
                continue
            }

            for key in requiredKeys {
                let localized = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
                #expect(localized != key, "Key '\(key)' is missing from \(folder).lproj/Localizable.strings")
                #expect(!localized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Key '\(key)' is empty in \(folder).lproj")
            }
        }
    }

    // MARK: - R2: Retention Policy and History Management

    @Test("Verify activity logs are capped at maximum capacity of 30 entries")
    @MainActor
    func testLogRetentionCapacityBuffer() {
        let controller = AppController.shared
        controller.clearLogs()

        for i in 1...35 {
            controller.appendLog(
                title: "Log #\(i)",
                detail: "Detail #\(i)",
                isSuccess: true,
                isAutomated: false
            )
        }

        #expect(controller.activityLogs.count == 30)
        // Most recent should be Log #35
        #expect(controller.activityLogs.first?.title == "Log #35")
        // Oldest retained should be Log #6 (Logs 1-5 pruned)
        #expect(controller.activityLogs.last?.title == "Log #6")
    }

    @Test("Verify activity logs older than 30 days are automatically pruned")
    @MainActor
    func testLogRetentionAgePruning() {
        let controller = AppController.shared
        controller.clearLogs()

        let now = Date()
        let daySeconds: TimeInterval = 86400

        // 35 days old (should be pruned)
        let oldItem = ActivityLogItem(
            timestamp: now.addingTimeInterval(-35 * daySeconds),
            title: "Old Log (35d)",
            detail: "Expired",
            isSuccess: true,
            isAutomated: false
        )

        // 20 days old (should be kept)
        let middleItem = ActivityLogItem(
            timestamp: now.addingTimeInterval(-20 * daySeconds),
            title: "Middle Log (20d)",
            detail: "Valid",
            isSuccess: true,
            isAutomated: false
        )

        // 2 hours old (should be kept)
        let recentItem = ActivityLogItem(
            timestamp: now.addingTimeInterval(-7200),
            title: "Recent Log",
            detail: "Fresh",
            isSuccess: true,
            isAutomated: false
        )

        controller.appendLog(oldItem)
        controller.appendLog(middleItem)
        controller.appendLog(recentItem)

        // Pruning against `now`
        controller.pruneLogs(referenceDate: now)

        #expect(controller.activityLogs.count == 2)
        #expect(controller.activityLogs.contains(where: { $0.title == "Recent Log" }))
        #expect(controller.activityLogs.contains(where: { $0.title == "Middle Log (20d)" }))
        #expect(!controller.activityLogs.contains(where: { $0.title == "Old Log (35d)" }))
    }

    @Test("Verify clearLogs removes all entries from display")
    @MainActor
    func testClearLogsFunctionality() {
        let controller = AppController.shared
        controller.appendLog(title: "Test", detail: "Test Detail", isSuccess: true, isAutomated: false)
        #expect(!controller.activityLogs.isEmpty)

        controller.clearLogs()
        #expect(controller.activityLogs.isEmpty)
    }

    @Test("Verify status indicators (success, failure, automated) are faithfully preserved")
    func testStatusIndicatorsIntegrity() {
        let manualSuccess = ActivityLogItem(
            title: "Manual Success",
            detail: "detail",
            isSuccess: true,
            isAutomated: false
        )
        let automatedSuccess = ActivityLogItem(
            title: "Automated Success",
            detail: "detail",
            isSuccess: true,
            isAutomated: true
        )
        let failureItem = ActivityLogItem(
            title: "Failure Item",
            detail: "detail",
            isSuccess: false,
            isAutomated: true
        )

        #expect(manualSuccess.isSuccess == true)
        #expect(manualSuccess.isAutomated == false)

        #expect(automatedSuccess.isSuccess == true)
        #expect(automatedSuccess.isAutomated == true)

        #expect(failureItem.isSuccess == false)
        #expect(failureItem.isAutomated == true)
    }

    // MARK: - Edge Cases: Concurrency & Immediate Pruning

    @Test("Verify thread-safe language switching and log resolution under concurrent access")
    func testConcurrentLanguageSwitchingStress() async {
        let testLanguages: [AppLanguage] = [.en, .zhHans, .zhHantTW, .zhHantHK, .ja]
        let sampleItem = ActivityLogItem(
            titleKey: "msg.ready.title",
            titleArgs: [],
            detailKey: "msg.ready.detail",
            detailArgs: [
                .sleepState(isSleepDisabled: true),
                .powerSnapshot(PowerSnapshot(source: .ac, batteryPercentage: 100))
            ],
            isSuccess: true,
            isAutomated: true
        )

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                let targetLang = testLanguages[i % testLanguages.count]
                group.addTask {
                    I18n.shared.setLanguage(targetLang)
                    let _ = I18n.shared.bundle(for: targetLang)
                    let title = sampleItem.localizedTitle(in: targetLang)
                    let detail = sampleItem.localizedDetail(in: targetLang)
                    #expect(!title.isEmpty)
                    #expect(!detail.isEmpty)
                }
            }
        }
    }

    @Test("Verify appendLog automatically prunes expired items older than 30 days immediately upon insertion")
    @MainActor
    func testAppendLogAutoPruningForExpiredLog() {
        let controller = AppController.shared
        controller.clearLogs()

        let now = Date()
        let daySeconds: TimeInterval = 86400

        let expiredItem = ActivityLogItem(
            timestamp: now.addingTimeInterval(-35 * daySeconds),
            titleKey: "msg.toggle.disabled",
            isSuccess: true,
            isAutomated: false
        )

        controller.appendLog(expiredItem)
        #expect(controller.activityLogs.isEmpty)

        let freshItem = ActivityLogItem(
            timestamp: now,
            titleKey: "msg.toggle.disabled",
            isSuccess: true,
            isAutomated: false
        )
        controller.appendLog(freshItem)
        #expect(controller.activityLogs.count == 1)
        #expect(controller.activityLogs.first?.id == freshItem.id)
    }

    @Test("Verify customDetailFormat with empty arguments returns empty string safely without crash or null formatting")
    func testEmptyArgsCustomDetailFormatSafety() {
        let safeItem = ActivityLogItem(
            titleKey: "msg.toggle.failed",
            titleArgs: [],
            detailKey: nil,
            detailArgs: [],
            customDetailFormat: "%@ — %@",
            isSuccess: false,
            isAutomated: false
        )
        #expect(safeItem.localizedDetail() == "")
        #expect(safeItem.localizedDetail(in: .en) == "")
        #expect(safeItem.localizedDetail(in: .ja) == "")
    }

    @Test("Verify language switching updates I18n before objectWillChange notification is dispatched")
    @MainActor
    func testLanguageSwitchingAtomicCombineEmission() {
        let controller = AppController.shared
        let originalLang = controller.appLanguage
        defer {
            controller.selectLanguage(originalLang)
        }

        var observedI18nLanguageDuringObjectWillChange: AppLanguage?
        var notificationCount = 0

        let cancellable = controller.objectWillChange.sink { _ in
            notificationCount += 1
            observedI18nLanguageDuringObjectWillChange = I18n.shared.currentLanguage
        }
        defer { cancellable.cancel() }

        let targetLang: AppLanguage = (originalLang == .en) ? .ja : .en
        controller.appLanguage = targetLang

        #expect(observedI18nLanguageDuringObjectWillChange == targetLang)
        #expect(notificationCount == 1)
    }

    @Test("Verify customDetailFormat with fewer arguments than format specifiers safely avoids (null) formatting")
    func testPartialArgsCustomDetailFormatSafety() {
        let partialItem = ActivityLogItem(
            titleKey: "msg.toggle.failed",
            titleArgs: [],
            detailKey: nil,
            detailArgs: [.string("Single Reason")],
            customDetailFormat: "%@ — %@",
            isSuccess: false,
            isAutomated: false
        )
        // With only 1 argument provided for a 2-specifier pattern "%@ — %@", it must format the argument without "(null)"
        let detailEN = partialItem.localizedDetail(in: .en)
        #expect(detailEN == "Single Reason")
        #expect(!detailEN.contains("(null)"))

        let detailZH = partialItem.localizedDetail(in: .zhHans)
        #expect(detailZH == "Single Reason")
        #expect(!detailZH.contains("(null)"))
    }

    @Test("Verify detailKey with empty or partial arguments avoids leaking format specifiers or (null)")
    func testEmptyAndPartialArgsDetailKeySafety() {
        // 1. Parameterized key with empty arguments returns "" safely
        let emptyArgsItem = ActivityLogItem(
            titleKey: "msg.ready.title",
            titleArgs: [],
            detailKey: "msg.ready.detail",
            detailArgs: [],
            isSuccess: true,
            isAutomated: true
        )
        #expect(emptyArgsItem.localizedDetail(in: .en) == "")
        #expect(emptyArgsItem.localizedDetail(in: .zhHans) == "")

        // 2. Parameterized key with 1 of 2 arguments safely outputs resolved argument without "(null)"
        let partialArgsItem = ActivityLogItem(
            titleKey: "msg.ready.title",
            titleArgs: [],
            detailKey: "msg.ready.detail",
            detailArgs: [.sleepState(isSleepDisabled: true)],
            isSuccess: true,
            isAutomated: true
        )
        let resolvedEN = partialArgsItem.localizedDetail(in: .en)
        #expect(resolvedEN.contains("1 (Sleep Disabled)"))
        #expect(!resolvedEN.contains("(null)"))
        #expect(!resolvedEN.contains("%@"))

        // 3. Static detailKey with no specifiers still resolves properly with empty arguments
        let staticDetailItem = ActivityLogItem(
            titleKey: "msg.launch.on",
            titleArgs: [],
            detailKey: "msg.launch.detail",
            detailArgs: [],
            isSuccess: true,
            isAutomated: false
        )
        #expect(staticDetailItem.localizedDetail(in: .en) == I18n.shared.localized("msg.launch.detail", in: .en))
        #expect(staticDetailItem.localizedDetail(in: .zhHans) == I18n.shared.localized("msg.launch.detail", in: .zhHans))
    }

    @Test("Verify future timestamp log does not cause premature deletion of legitimate current logs")
    @MainActor
    func testFutureTimestampDoesNotPruneExistingLogs() {
        let controller = AppController.shared
        controller.clearLogs()

        let now = Date()

        // Append 5 fresh logs
        for i in 1...5 {
            controller.appendLog(
                title: "Log #\(i)",
                detail: "Detail #\(i)",
                isSuccess: true,
                isAutomated: false
            )
        }
        #expect(controller.activityLogs.count == 5)

        // Append an item with a future timestamp (e.g. clock drift or synthetic future log)
        let futureItem = ActivityLogItem(
            timestamp: now.addingTimeInterval(35 * 86400),
            title: "Future Log (+35d)",
            detail: "Future",
            isSuccess: true,
            isAutomated: false
        )
        controller.appendLog(futureItem)

        // With the fix, current logs are NOT wiped out
        #expect(controller.activityLogs.count == 6)
        #expect(controller.activityLogs.contains(where: { $0.title == "Log #1" }))
        #expect(controller.activityLogs.contains(where: { $0.title == "Log #5" }))
        #expect(controller.activityLogs.contains(where: { $0.title == "Future Log (+35d)" }))
    }

    @Test("Verify all 8 activity log event types dynamically re-localize across all supported locales")
    @MainActor
    func testAllLogEventTypesDynamicLanguageSwitching() {
        let initialLang = I18n.shared.currentLanguage
        defer {
            I18n.shared.setLanguage(initialLang)
        }

        let controller = AppController.shared
        controller.clearLogs()

        let snapshot = PowerSnapshot(source: .ac, batteryPercentage: 100, isCharging: false, isCharged: true)

        controller.logReady(isSleepDisabled: true, powerSnapshot: snapshot)
        controller.logExternalChange(isSleepDisabled: false)
        controller.logToggleSuccess(targetDisable: true, reasonKey: "msg.reason.manual", isAutomated: false)
        controller.logToggleFailure(reasonKey: "msg.reason.hero_switch", error: SleepControlError.userCanceledAuth, isAutomated: false)
        controller.logPowerTransition(newSnapshot: snapshot)
        controller.logAutoDisableChanged(enabled: true)
        controller.logPasswordlessAuthChanged(enabled: true)
        controller.logLaunchAtLoginChanged(enabled: true)

        #expect(controller.activityLogs.count == 8)

        for lang in supportedLanguages {
            controller.selectLanguage(lang)
            for item in controller.activityLogs {
                #expect(!item.title.isEmpty, "Empty title in language \(lang.rawValue) for key \(item.titleKey)")
                #expect(!item.detail.isEmpty, "Empty detail in language \(lang.rawValue) for item \(item.titleKey)")
                #expect(!item.detail.contains("(null)"), "Leaked (null) in \(lang.rawValue) for item \(item.titleKey)")
                #expect(!item.detail.contains("%@"), "Leaked %@ in \(lang.rawValue) for item \(item.titleKey)")
            }
        }
    }
}

