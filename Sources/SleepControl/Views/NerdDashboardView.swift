import SwiftUI
import AppKit

private final class NerdDashboardRevealState: ObservableObject {
    @Published var cardsRevealed: Bool = false
}

/// Right-side expandable diagnostic & engineering console ("Nerd Drawer") that dynamically
/// inherits the Editorial Magazine Cover's Awake (Warm Alabaster) or Sleeping (Deep Obsidian) palette.
struct NerdDashboardView: View {
    @ObservedObject var controller: AppController
    @StateObject private var revealState = NerdDashboardRevealState()

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let fg = EditorialTheme.foregroundColor(isAwake: isAwake)
        let hairline = EditorialTheme.hairlineColor(isAwake: isAwake)

        ZStack {
            EditorialTheme.backgroundColor(isAwake: isAwake)

            VStack(spacing: 0) {
                // Drawer Header
                headerBar(isAwake: isAwake, fg: fg)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                Rectangle()
                    .fill(hairline)
                    .frame(height: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // 1. Smart Power Automation
                        powerAutomationCard(isAwake: isAwake, fg: fg)
                            .bentoReveal(revealed: revealState.cardsRevealed, index: 0)

                        // 2. Passwordless Authorization & System Settings
                        privilegeAndSystemCard(isAwake: isAwake, fg: fg)
                            .bentoReveal(revealed: revealState.cardsRevealed, index: 1)

                        // 3. Low-level pmset Telemetry
                        telemetryCard(isAwake: isAwake, fg: fg)
                            .bentoReveal(revealed: revealState.cardsRevealed, index: 2)

                        // 4. Real-Time Activity Log Timeline
                        activityLogCard(isAwake: isAwake, fg: fg)
                            .bentoReveal(revealed: revealState.cardsRevealed, index: 3)

                        // 5. Version Footer
                        HStack {
                            Text(LF("dashboard.version", AppVersion.raw()))
                                .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(fg.opacity(0.40))
                            Spacer()
                            Text(L("window.main.badge"))
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundStyle(fg.opacity(0.40))
                        }
                        .padding(.top, 2)
                        .bentoReveal(revealed: revealState.cardsRevealed, index: 4)
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 520)
        .animation(.easeInOut(duration: 0.35), value: isAwake)
        .onAppear {
            revealState.cardsRevealed = false
            DispatchQueue.main.async {
                revealState.cardsRevealed = true
            }
        }
        .onDisappear {
            revealState.cardsRevealed = false
        }
    }

    // MARK: - Header Bar

    private func headerBar(isAwake: Bool, fg: Color) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("window.main.title"))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(fg)
                Text(L("window.main.subtitle"))
                    .font(.system(size: 11))
                    .foregroundStyle(fg.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Sync telemetry button
            Button {
                controller.refreshAllState()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10.5, weight: .semibold))
                    Text(L("action.sync"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(fg.opacity(0.85))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(fg.opacity(isAwake ? 0.05 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(EditorialTheme.hairlineColor(isAwake: isAwake), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)

            // Collapse drawer button
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    controller.isNerdDrawerExpanded = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(fg.opacity(0.70))
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(fg.opacity(isAwake ? 0.05 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(EditorialTheme.hairlineColor(isAwake: isAwake), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Smart Power Automation Card

    private func powerAutomationCard(isAwake: Bool, fg: Color) -> some View {
        EditorialSectionCard(isAwake: isAwake) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.badge.automatic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(EditorialTheme.amberAccent)

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(L("auto.card.title"))
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(fg)
                        Text(L("auto.card.subtitle"))
                            .font(.system(size: 11))
                            .foregroundStyle(fg.opacity(0.60))
                    }

                    Spacer()

                    Toggle("", isOn: $controller.autoDisableOnAC)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(EditorialTheme.amberAccent)
                        .labelsHidden()
                }

                Rectangle()
                    .fill(EditorialTheme.hairlineColor(isAwake: isAwake))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 6) {
                    ruleRow(
                        icon: "powerplug.fill",
                        title: L("auto.rule.ac.title"),
                        action: L("auto.rule.ac.action"),
                        isActive: controller.autoDisableOnAC && controller.powerSnapshot.source == .ac,
                        isAwake: isAwake,
                        fg: fg
                    )
                    ruleRow(
                        icon: "battery.75percent",
                        title: L("auto.rule.battery.title"),
                        action: L("auto.rule.battery.action"),
                        isActive: controller.autoDisableOnAC && controller.powerSnapshot.source == .battery,
                        isAwake: isAwake,
                        fg: fg
                    )
                }
            }
        }
    }

    private func ruleRow(
        icon: String,
        title: String,
        action: String,
        isActive: Bool,
        isAwake: Bool,
        fg: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? EditorialTheme.amberAccent : fg.opacity(0.55))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.92))
                    if isActive {
                        Text(L("auto.rule.active_badge"))
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(EditorialTheme.amberAccent.opacity(0.20)))
                            .foregroundStyle(EditorialTheme.amberAccent)
                    }
                }
                Text(action)
                    .font(.system(size: 10.5))
                    .foregroundStyle(fg.opacity(0.60))
            }
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? EditorialTheme.amberAccent.opacity(0.08) : fg.opacity(0.03))
        )
    }

    // MARK: - Privilege & System Settings Card

    private func privilegeAndSystemCard(isAwake: Bool, fg: Color) -> some View {
        EditorialSectionCard(isAwake: isAwake) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: controller.isPasswordlessConfigured ? "checkmark.shield.fill" : "lock.shield.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(controller.isPasswordlessConfigured ? EditorialTheme.amberAccent : fg.opacity(0.70))

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(L("priv.card.title"))
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(fg)
                        Text(controller.isPasswordlessConfigured
                             ? L("priv.card.subtitle.enabled")
                             : L("priv.card.subtitle.disabled"))
                            .font(.system(size: 10.5))
                            .foregroundStyle(fg.opacity(0.60))
                    }
                    Spacer()
                }

                Rectangle()
                    .fill(EditorialTheme.hairlineColor(isAwake: isAwake))
                    .frame(height: 1)

                // Passwordless sudoers row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(controller.isPasswordlessConfigured ? Color.green : EditorialTheme.amberAccent)
                                .frame(width: 6.5, height: 6.5)
                            Text(controller.isPasswordlessConfigured ? L("priv.status.enabled") : L("priv.status.disabled"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(fg)
                        }
                        Text(L("priv.status.detail"))
                            .font(.system(size: 10.5))
                            .foregroundStyle(fg.opacity(0.60))
                    }

                    Spacer()

                    if controller.isPasswordlessConfigured {
                        Button(L("priv.btn.revoke")) {
                            controller.revokePasswordlessSudo()
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(fg.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .strokeBorder(EditorialTheme.hairlineColor(isAwake: isAwake), lineWidth: 0.9)
                        )
                        .buttonStyle(.plain)
                        .disabled(controller.isBusy)
                    } else {
                        Button(L("priv.btn.enable")) {
                            controller.configurePasswordlessSudo()
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(EditorialTheme.backgroundColor(isAwake: isAwake))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(fg))
                        .buttonStyle(.plain)
                        .disabled(controller.isBusy)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(fg.opacity(0.03))
                )

                // Launch at login row
                HStack {
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(L("system.launch.title"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(fg)
                        Text(L("system.launch.subtitle"))
                            .font(.system(size: 10.5))
                            .foregroundStyle(fg.opacity(0.60))
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { controller.launchAtLoginEnabled },
                        set: { _ in controller.toggleLaunchAtLogin() }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(EditorialTheme.amberAccent)
                    .labelsHidden()
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Low-level pmset Telemetry Card

    private func telemetryCard(isAwake: Bool, fg: Color) -> some View {
        EditorialSectionCard(isAwake: isAwake) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(L("telemetry.card.title"), systemImage: "cpu")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(fg)
                    Spacer()
                    Text("/usr/bin/pmset -g")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(fg.opacity(0.55))
                }

                Rectangle()
                    .fill(EditorialTheme.hairlineColor(isAwake: isAwake))
                    .frame(height: 1)

                VStack(spacing: 6) {
                    telemetryRow(
                        label: L("telemetry.row.sleepdisabled"),
                        value: controller.isSleepDisabled ? L("telemetry.val.disabled") : L("telemetry.val.enabled"),
                        highlightColor: controller.isSleepDisabled ? EditorialTheme.amberAccent : fg.opacity(0.9),
                        fg: fg
                    )
                    telemetryRow(
                        label: L("telemetry.row.powersource"),
                        value: controller.powerSnapshot.formattedSummary,
                        highlightColor: nil,
                        fg: fg
                    )
                    telemetryRow(
                        label: L("telemetry.row.displaysleep"),
                        value: controller.telemetry.displaySleepFormatted,
                        highlightColor: nil,
                        fg: fg
                    )
                    telemetryRow(
                        label: L("telemetry.row.systemsleep"),
                        value: controller.telemetry.systemSleepFormatted,
                        highlightColor: nil,
                        fg: fg
                    )
                    telemetryRow(
                        label: L("telemetry.row.hibernatemode"),
                        value: controller.telemetry.hibernateModeFormatted,
                        highlightColor: nil,
                        fg: fg
                    )
                }
            }
        }
    }

    private func telemetryRow(label: String, value: String, highlightColor: Color?, fg: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(fg.opacity(0.65))
            Spacer()
            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(highlightColor ?? fg.opacity(0.92))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(fg.opacity(0.03))
        )
    }

    // MARK: - Activity Log Card

    private func activityLogCard(isAwake: Bool, fg: Color) -> some View {
        EditorialSectionCard(isAwake: isAwake) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(L("log.card.title"), systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(fg)
                    Spacer()
                    if !controller.activityLogs.isEmpty {
                        Button(L("log.btn.clear")) {
                            controller.clearLogs()
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(fg.opacity(0.60))
                    }
                }

                Rectangle()
                    .fill(EditorialTheme.hairlineColor(isAwake: isAwake))
                    .frame(height: 1)

                if controller.activityLogs.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 18))
                            .foregroundStyle(fg.opacity(0.35))
                        Text(L("log.empty"))
                            .font(.system(size: 11.5))
                            .foregroundStyle(fg.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(controller.activityLogs.prefix(8)) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(log.isSuccess ? (log.isAutomated ? EditorialTheme.amberAccent : Color.green) : Color.red)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 1.5) {
                                    HStack {
                                        Text(log.title)
                                            .font(.system(size: 11.5, weight: .semibold))
                                            .foregroundStyle(fg.opacity(0.92))
                                        Spacer()
                                        Text(log.formattedTime)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(fg.opacity(0.45))
                                    }
                                    Text(log.detail)
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(fg.opacity(0.62))
                                        .lineLimit(2)
                                }
                            }
                            .padding(6.5)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(fg.opacity(0.03))
                            )
                        }
                    }
                }
            }
        }
    }
}

private extension View {
    func bentoReveal(revealed: Bool, index: Int) -> some View {
        self
            .opacity(revealed ? 1 : 0)
            .offset(x: revealed ? 0 : 12, y: revealed ? 0 : 6)
            .animation(
                .spring(response: 0.34, dampingFraction: 0.82)
                    .delay(Double(index) * 0.028),
                value: revealed
            )
    }
}
