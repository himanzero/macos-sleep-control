import SwiftUI
import AppKit

/// Frosted glass popover control panel presented from the macOS menu bar
struct MenuBarPopoverView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(spacing: 12) {
            // Header: Branding, Language Switcher, and Sudoers Authorization Badge
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Group {
                    if let img = NSImage(named: controller.isSleepDisabled ? "status_cat_awake" : "status_cat_sleeping") {
                        Image(nsImage: img)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: controller.isSleepDisabled ? "cat" : "cat.fill")
                    }
                }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accentColor(isSleepDisabled: controller.isSleepDisabled))
                    Text(L("app.name"))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Text(L("app.subtitle"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 4)

                // Compact language switcher
                LanguageSwitcherMenu(controller: controller, isCompact: true)
                    .fixedSize()

                // Passwordless authorization indicator badge
                Button {
                    if !controller.isPasswordlessConfigured {
                        controller.configurePasswordlessSudo()
                    } else {
                        openMainDashboard()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: controller.isPasswordlessConfigured ? "checkmark.shield.fill" : "key.fill")
                            .font(.system(size: 10))
                        Text(controller.isPasswordlessConfigured ? L("priv.badge.enabled") : L("priv.badge.disabled"))
                            .font(.system(size: 10.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(controller.isPasswordlessConfigured
                                  ? Color.green.opacity(0.16)
                                  : Color.orange.opacity(0.18))
                    )
                    .foregroundStyle(controller.isPasswordlessConfigured ? Color.green : Color.orange)
                }
                .buttonStyle(.plain)
                .help(controller.isPasswordlessConfigured ? L("priv.help.enabled") : L("priv.help.disabled"))
            }
            .padding(.horizontal, 4)

            // Core hero status card with main toggle
            StatusHeroCard(controller: controller, isCompact: true)

            // Smart AC power automation options card
            GlassCard(padding: 13, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.green.opacity(0.16))
                                .frame(width: 34, height: 34)
                            Image(systemName: "powerplug.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("auto.menubar.title"))
                                .font(.system(size: 13, weight: .semibold))
                            Text(L("auto.menubar.subtitle"))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $controller.autoDisableOnAC)
                            .toggleStyle(.switch)
                            .tint(.green)
                            .labelsHidden()
                    }

                    // Prompt to configure passwordless authorization if automation is enabled but not yet authorized
                    if controller.autoDisableOnAC && !controller.isPasswordlessConfigured {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundStyle(.orange)
                            Text(L("auto.tip.passwordless"))
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(L("auto.tip.configure_btn")) {
                                controller.configurePasswordlessSudo()
                            }
                            .font(.system(size: 10.5, weight: .semibold))
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.mini)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.10))
                        )
                    }
                }
            }

            // Notification / error banner
            if let message = controller.bannerMessage {
                HStack(spacing: 8) {
                    Image(systemName: controller.isBannerError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(controller.isBannerError ? .red : .blue)
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        controller.clearBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((controller.isBannerError ? Color.red : Color.blue).opacity(0.12))
                )
            }

            // Bottom action buttons
            HStack(spacing: 10) {
                Button {
                    openMainDashboard()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11.5))
                        Text(L("action.open_dashboard"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    controller.refreshAllState()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text(L("action.refresh"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text(L("action.quit"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(minWidth: 350, idealWidth: 400, maxWidth: 540)
    }

    private func openMainDashboard() {
        StatusItemManager.shared.showMainWindow()
    }
}
