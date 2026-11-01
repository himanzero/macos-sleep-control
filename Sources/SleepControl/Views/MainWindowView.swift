import SwiftUI
import AppKit

/// Standalone main dashboard window adopting modern macOS Sequoia Bento-grid design
struct MainWindowView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        ZStack {
            // Multi-layered Aurora ambient backdrop
            AuroraAmbientBackdrop(isSleepDisabled: controller.isSleepDisabled, intensity: 1.0)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header title, language switcher, and toolbar actions
                    headerSection

                    // Notification / Error banner (if active)
                    if let banner = controller.bannerMessage {
                        bannerSection(banner)
                    }

                    // 1. Hero Status Card
                    StatusHeroCard(controller: controller, isCompact: false)

                    // 2. Middle Bento Row: Smart Power Automation + Privilege & System Settings
                    HStack(alignment: .top, spacing: 16) {
                        powerAutomationCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                        privilegeAndSystemCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    // 3. Bottom Bento Row: Low-level pmset Telemetry + Activity Log Timeline
                    HStack(alignment: .top, spacing: 16) {
                        telemetryCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                        activityLogCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
        }
        .frame(minWidth: 780, idealWidth: 850, minHeight: 760, idealHeight: 830)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text(L("window.main.title"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(L("window.main.badge"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.primary.opacity(0.07)))
                        .foregroundStyle(.secondary)
                }
                Text(L("window.main.subtitle"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Language switcher dropdown menu
            LanguageSwitcherMenu(controller: controller, isCompact: false)

            Button {
                controller.refreshAllState()
            } label: {
                Label(L("action.sync"), systemImage: "arrow.clockwise")
                    .font(.system(size: 12.5, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.regularMaterial)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Banner Section

    private func bannerSection(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: controller.isBannerError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(controller.isBannerError ? .red : .green)
            Text(message)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Button {
                controller.clearBanner()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((controller.isBannerError ? Color.red : Color.green).opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder((controller.isBannerError ? Color.red : Color.green).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Smart Power Automation Card

    private var powerAutomationCard: some View {
        GlassCard(padding: 18, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.opacity(0.16))
                            .frame(width: 38, height: 38)
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("auto.card.title"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(L("auto.card.subtitle"))
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $controller.autoDisableOnAC)
                        .toggleStyle(.switch)
                        .tint(.green)
                        .labelsHidden()
                }

                Divider().opacity(0.5)

                // Automation rules description
                VStack(alignment: .leading, spacing: 8) {
                    ruleRow(
                        icon: "powerplug.fill",
                        iconColor: .green,
                        title: L("auto.rule.ac.title"),
                        action: L("auto.rule.ac.action"),
                        isActive: controller.autoDisableOnAC && controller.powerSnapshot.source == .ac
                    )
                    ruleRow(
                        icon: "battery.75percent",
                        iconColor: .orange,
                        title: L("auto.rule.battery.title"),
                        action: L("auto.rule.battery.action"),
                        isActive: controller.autoDisableOnAC && controller.powerSnapshot.source == .battery
                    )
                }
            }
        }
    }

    private func ruleRow(icon: String, iconColor: Color, title: String, action: String, isActive: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                    if isActive {
                        Text(L("auto.rule.active_badge"))
                            .font(.system(size: 9.5, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(iconColor.opacity(0.2)))
                            .foregroundStyle(iconColor)
                    }
                }
                Text(action)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive ? iconColor.opacity(0.08) : Color.primary.opacity(0.04))
        )
    }

    // MARK: - Passwordless Authorization & System Settings Card

    private var privilegeAndSystemCard: some View {
        GlassCard(padding: 18, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((controller.isPasswordlessConfigured ? Color.blue : Color.orange).opacity(0.16))
                            .frame(width: 38, height: 38)
                        Image(systemName: controller.isPasswordlessConfigured ? "checkmark.shield.fill" : "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(controller.isPasswordlessConfigured ? .blue : .orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("priv.card.title"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(controller.isPasswordlessConfigured
                             ? L("priv.card.subtitle.enabled")
                             : L("priv.card.subtitle.disabled"))
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.5)

                // Passwordless sudo row
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(controller.isPasswordlessConfigured ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text(controller.isPasswordlessConfigured ? L("priv.status.enabled") : L("priv.status.disabled"))
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        Text(L("priv.status.detail"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if controller.isPasswordlessConfigured {
                        Button(L("priv.btn.revoke")) {
                            controller.revokePasswordlessSudo()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(controller.isBusy)
                    } else {
                        Button(L("priv.btn.enable")) {
                            controller.configurePasswordlessSudo()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                        .disabled(controller.isBusy)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )

                // Launch at login row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("system.launch.title"))
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(L("system.launch.subtitle"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { controller.launchAtLoginEnabled },
                        set: { _ in controller.toggleLaunchAtLogin() }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding(.horizontal, 6)

                // Interface language selection row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("lang.setting.title"))
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(L("lang.setting.subtitle"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    LanguageSwitcherMenu(controller: controller, isCompact: false)
                }
                .padding(.horizontal, 6)
            }
        }
    }

    // MARK: - Low-level pmset Telemetry Card

    private var telemetryCard: some View {
        GlassCard(padding: 18, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(L("telemetry.card.title"), systemImage: "cpu.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    Text("/usr/bin/pmset -g")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Divider().opacity(0.5)

                VStack(spacing: 8) {
                    telemetryRow(
                        label: L("telemetry.row.sleepdisabled"),
                        value: controller.isSleepDisabled ? L("telemetry.val.disabled") : L("telemetry.val.enabled"),
                        highlightColor: controller.isSleepDisabled ? .orange : .cyan
                    )
                    telemetryRow(
                        label: L("telemetry.row.powersource"),
                        value: controller.powerSnapshot.formattedSummary,
                        highlightColor: nil
                    )
                    telemetryRow(
                        label: L("telemetry.row.displaysleep"),
                        value: controller.telemetry.displaySleepFormatted,
                        highlightColor: nil
                    )
                    telemetryRow(
                        label: L("telemetry.row.systemsleep"),
                        value: controller.telemetry.systemSleepFormatted,
                        highlightColor: nil
                    )
                    telemetryRow(
                        label: L("telemetry.row.hibernatemode"),
                        value: controller.telemetry.hibernateModeFormatted,
                        highlightColor: nil
                    )
                }
            }
        }
    }

    private func telemetryRow(label: String, value: String, highlightColor: Color?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(highlightColor ?? .primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }

    // MARK: - Real-Time Activity Log Card

    private var activityLogCard: some View {
        GlassCard(padding: 18, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(L("log.card.title"), systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    if !controller.activityLogs.isEmpty {
                        Button(L("log.btn.clear")) {
                            controller.clearLogs()
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }

                Divider().opacity(0.5)

                if controller.activityLogs.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                        Text(L("log.empty"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 130)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(controller.activityLogs.prefix(8)) { log in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(log.isSuccess ? (log.isAutomated ? Color.cyan : Color.green) : Color.red)
                                        .frame(width: 7, height: 7)
                                        .padding(.top, 5)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(log.title)
                                                .font(.system(size: 12, weight: .semibold))
                                            Spacer()
                                            Text(log.formattedTime)
                                                .font(.system(size: 10.5, design: .monospaced))
                                                .foregroundStyle(.tertiary)
                                        }
                                        Text(log.detail)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.primary.opacity(0.035))
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 175)
                }
            }
        }
    }
}
