import SwiftUI

// MARK: - Modern macOS Visual Theme & Materials

enum AppTheme {
    /// Active keep-awake gradient (warm amber glow)
    static let awakeGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.58, blue: 0.12),
            Color(red: 0.96, green: 0.36, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Standard sleep allowed gradient (deep space indigo glow)
    static let sleepAllowedGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.48, blue: 0.98),
            Color(red: 0.38, green: 0.26, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func accentColor(isSleepDisabled: Bool) -> Color {
        isSleepDisabled
            ? Color(red: 1.00, green: 0.55, blue: 0.12)
            : Color(red: 0.30, green: 0.52, blue: 0.98)
    }
}

/// Modern macOS Bento frosted glass container card
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

/// Universal language switcher menu button (supports compact icon badge and full label modes)
struct LanguageSwitcherMenu: View {
    @ObservedObject var controller: AppController
    var isCompact: Bool = false

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    controller.selectLanguage(lang)
                } label: {
                    HStack {
                        Text(lang.displayTitle(in: nil))
                        if controller.appLanguage == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: isCompact ? 11 : 12, weight: .medium))
                Text(isCompact ? controller.appLanguage.shortBadgeCode : controller.appLanguage.nativeName)
                    .font(.system(size: isCompact ? 10.5 : 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 7 : 9, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(L("lang.menu.title"))
    }
}

/// Hero status card displaying live state, animated icon, and main toggle switch
struct StatusHeroCard: View {
    @ObservedObject var controller: AppController
    var isCompact: Bool = false

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let accent = AppTheme.accentColor(isSleepDisabled: isAwake)

        ZStack {
            // Background dynamic blur & ambient glow
            RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous)
                .fill(isAwake ? AppTheme.awakeGradient : AppTheme.sleepAllowedGradient)
                .opacity(0.16)

            // Ambient background glow orb
            Circle()
                .fill(accent.opacity(0.28))
                .frame(width: isCompact ? 130 : 180, height: isCompact ? 130 : 180)
                .blur(radius: 36)
                .offset(x: isCompact ? 90 : 150, y: -40)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
                HStack(alignment: .center, spacing: 14) {
                    // Animated status badge icon
                    ZStack {
                        Circle()
                            .fill(isAwake ? AppTheme.awakeGradient : AppTheme.sleepAllowedGradient)
                            .frame(width: isCompact ? 46 : 56, height: isCompact ? 46 : 56)
                            .shadow(color: accent.opacity(0.45), radius: 10, x: 0, y: 4)

                        Image(systemName: isAwake ? "cup.and.saucer.fill" : "moon.stars.fill")
                            .font(.system(size: isCompact ? 20 : 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: isAwake)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(isAwake ? L("hero.status.disabled") : L("hero.status.enabled"))
                                .font(.system(size: isCompact ? 16 : 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            // Telemetry tag capsule
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isAwake ? Color.orange : Color.cyan)
                                    .frame(width: 6, height: 6)
                                Text(isAwake ? "disablesleep 1" : "disablesleep 0")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.16))
                            )
                            .foregroundStyle(accent)
                        }

                        Text(isAwake ? L("hero.desc.disabled") : L("hero.desc.enabled"))
                            .font(.system(size: isCompact ? 11.5 : 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    // Main control toggle switch
                    if controller.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 44, height: 28)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { controller.isSleepDisabled },
                            set: { newValue in
                                controller.setSleepDisabled(newValue, isAutomated: false, reason: L("msg.reason.hero_switch"))
                            }
                        ))
                        .toggleStyle(.switch)
                        .tint(accent)
                        .labelsHidden()
                        .scaleEffect(isCompact ? 1.05 : 1.15)
                    }
                }

                Divider()
                    .opacity(0.5)

                // Bottom telemetry and quick action strip
                HStack(spacing: 10) {
                    // Power source snapshot capsule
                    Label {
                        Text(controller.powerSnapshot.formattedSummary)
                            .font(.system(size: 11.5, weight: .medium))
                    } icon: {
                        Image(systemName: controller.powerSnapshot.source.symbolName)
                            .foregroundStyle(controller.powerSnapshot.source == .ac ? .green : .orange)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )

                    Spacer()

                    // Quick toggle button
                    Button {
                        controller.toggleSleepDisabled()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: isAwake ? "moon.fill" : "bolt.shield.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(isAwake ? L("hero.button.allow_sleep") : L("hero.button.disable_sleep"))
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(accent.opacity(0.18))
                        )
                        .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(controller.isBusy)
                }
            }
            .padding(isCompact ? 15 : 20)
        }
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.45),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 6)
    }
}
