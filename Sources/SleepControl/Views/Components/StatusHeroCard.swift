import SwiftUI
import AppKit

// MARK: - Modern macOS Aurora Visual Theme & Materials

enum AppTheme {
    /// Active keep-awake gradient (warm golden-amber sunrise glow)
    static let awakeGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.64, blue: 0.14),
            Color(red: 0.98, green: 0.42, blue: 0.16),
            Color(red: 0.92, green: 0.28, blue: 0.24)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Standard sleep allowed gradient (dreamy midnight indigo-violet nebula)
    static let sleepAllowedGradient = LinearGradient(
        colors: [
            Color(red: 0.24, green: 0.52, blue: 0.98),
            Color(red: 0.42, green: 0.30, blue: 0.92),
            Color(red: 0.56, green: 0.24, blue: 0.86)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func accentColor(isSleepDisabled: Bool) -> Color {
        isSleepDisabled
            ? Color(red: 1.00, green: 0.58, blue: 0.14)
            : Color(red: 0.36, green: 0.56, blue: 0.98)
    }

    static func secondaryOrbColor(isSleepDisabled: Bool) -> Color {
        isSleepDisabled
            ? Color(red: 0.98, green: 0.34, blue: 0.26)
            : Color(red: 0.58, green: 0.28, blue: 0.92)
    }
}

/// Multi-layered Aurora ambient backdrop for windows and popovers
struct AuroraAmbientBackdrop: View {
    var isSleepDisabled: Bool
    var intensity: Double = 1.0

    var body: some View {
        let primary = AppTheme.accentColor(isSleepDisabled: isSleepDisabled)
        let secondary = AppTheme.secondaryOrbColor(isSleepDisabled: isSleepDisabled)

        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let driftX = 0.08 * sin(t * 0.7)
            let driftY = 0.06 * cos(t * 0.55)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                // Top-left primary aurora nebula
                RadialGradient(
                    colors: [
                        primary.opacity(0.22 * intensity),
                        primary.opacity(0.08 * intensity),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.14 + driftX, y: 0.12 + driftY),
                    startRadius: 12,
                    endRadius: 460
                )

                // Bottom-right secondary aurora glow
                RadialGradient(
                    colors: [
                        secondary.opacity(0.18 * intensity),
                        secondary.opacity(0.05 * intensity),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.86 - driftX, y: 0.84 - driftY),
                    startRadius: 20,
                    endRadius: 420
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.45), value: isSleepDisabled)
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
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 5)
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

/// Animated companion cat stage with breathing motion, floating sleep 'zZ' or awake sparkles, and interactive petting
struct CompanionCatStage: View {
    @ObservedObject var controller: AppController
    let isCompact: Bool

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let stageSize: CGFloat = isCompact ? 58 : 76
        let catSize: CGFloat = isCompact ? 42 : 56
        let accent = AppTheme.accentColor(isSleepDisabled: isAwake)

        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathWave = 0.5 + 0.5 * sin(t * 2.4)          // 0.0 ... 1.0 smooth breathing
            let particleWave = 0.5 + 0.5 * sin(t * 3.1 + 0.8)  // 0.0 ... 1.0 particle float

            Button {
                controller.petCompanion()
            } label: {
                ZStack {
                    // Outer breathing halo ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accent.opacity(0.18 + 0.22 * breathWave),
                                    accent.opacity(0.02),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: stageSize * 0.25,
                                endRadius: stageSize * 0.72
                            )
                        )
                        .frame(width: stageSize * 1.26, height: stageSize * 1.26)
                        .scaleEffect(0.94 + 0.14 * breathWave)

                    // Ambient scene orb (Golden Sun vs Starry Night)
                    Circle()
                        .fill(isAwake ? AppTheme.awakeGradient : AppTheme.sleepAllowedGradient)
                        .frame(width: stageSize, height: stageSize)
                        .shadow(color: accent.opacity(0.48), radius: 8 + 6 * breathWave, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.55),
                                            Color.white.opacity(0.10)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    // Subtle starry night dots or sunbeam ring inside the orb
                    if isAwake {
                        Circle()
                            .stroke(Color.yellow.opacity(0.20 + 0.25 * breathWave), lineWidth: 1.2)
                            .frame(width: stageSize - 8, height: stageSize - 8)
                            .scaleEffect(0.96 + 0.06 * breathWave)
                    } else {
                        // Twinkling micro-stars inside night orb
                        Group {
                            Circle()
                                .fill(Color.white.opacity(0.35 + 0.55 * particleWave))
                                .frame(width: 3, height: 3)
                                .offset(x: -stageSize * 0.28, y: -stageSize * 0.22)
                            Circle()
                                .fill(Color.cyan.opacity(0.90 - 0.50 * particleWave))
                                .frame(width: 2.5, height: 2.5)
                                .offset(x: stageSize * 0.26, y: stageSize * 0.22)
                        }
                    }

                    // Core cat artwork with gentle breathing & floating motion
                    Group {
                        if let heroImg = NSImage(named: isAwake ? "hero_cat_awake" : "hero_cat_sleeping") {
                            Image(nsImage: heroImg)
                                .renderingMode(.original)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: catSize, height: catSize)
                        } else if let img = NSImage(named: isAwake ? "status_cat_awake" : "status_cat_sleeping") {
                            Image(nsImage: img)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: catSize * 0.78, height: catSize * 0.78)
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: isAwake ? "cat" : "cat.fill")
                                .font(.system(size: catSize * 0.65, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(controller.isPetBouncing ? 1.18 : (0.97 + 0.08 * breathWave))
                    .offset(y: 1.8 - 3.6 * breathWave)
                    .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 2)

                    // Floating ambient particles: 'z z Z' when sleeping, sparkles when awake
                    if isAwake {
                        Image(systemName: "sparkles")
                            .font(.system(size: isCompact ? 11 : 13, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.45))
                            .shadow(color: .orange.opacity(0.6), radius: 4)
                            .offset(
                                x: stageSize * 0.40,
                                y: -stageSize * 0.36 + (2.0 - 4.5 * particleWave)
                            )
                            .scaleEffect(0.88 + 0.26 * particleWave)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: isCompact ? 9 : 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.35))
                            .offset(
                                x: -stageSize * 0.40,
                                y: -stageSize * 0.28 + (-2.0 + 4.0 * particleWave)
                            )
                            .opacity(0.55 + 0.40 * particleWave)
                    } else {
                        // Floating 'z z Z' sleep bubble particles
                        ZStack {
                            Text("z")
                                .font(.system(size: isCompact ? 9 : 10.5, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.72, green: 0.86, blue: 1.0))
                                .offset(
                                    x: stageSize * 0.32,
                                    y: -stageSize * 0.24 + (2.0 - 5.0 * particleWave)
                                )
                                .opacity(0.95 - 0.30 * particleWave)

                            Text("Z")
                                .font(.system(size: isCompact ? 11.5 : 13.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: Color.cyan.opacity(0.6), radius: 4)
                                .offset(
                                    x: stageSize * 0.46,
                                    y: -stageSize * 0.42 + (1.5 - 6.0 * particleWave)
                                )
                                .scaleEffect(0.92 + 0.18 * particleWave)
                                .opacity(0.65 + 0.35 * particleWave)
                        }
                    }

                    // Interactive heart pop when user pets the cat
                    if controller.showPetHeart {
                        Image(systemName: "heart.fill")
                            .font(.system(size: isCompact ? 12 : 15, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.52))
                            .shadow(color: .pink.opacity(0.6), radius: 5)
                            .offset(x: -stageSize * 0.36, y: -stageSize * 0.44)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: stageSize + 14, height: stageSize + 10)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(L("companion.pet.hint"))
        }
    }
}

/// Hero status card displaying the living cat companion scene, emotional dialogue bubble, live state, and main toggle switch
struct StatusHeroCard: View {
    @ObservedObject var controller: AppController
    var isCompact: Bool = false

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let accent = AppTheme.accentColor(isSleepDisabled: isAwake)
        let secondaryOrb = AppTheme.secondaryOrbColor(isSleepDisabled: isAwake)
        let radius: CGFloat = isCompact ? 16 : 22

        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
            let auraWave = 0.5 + 0.5 * sin(context.date.timeIntervalSinceReferenceDate * 1.8)

            ZStack {
                // 1. Multi-stop Aurora mesh & frosted glass card backdrop
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(isAwake ? AppTheme.awakeGradient : AppTheme.sleepAllowedGradient)
                    .opacity(0.18)

                // Top-leading warm/starry radial aurora orb
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                accent.opacity(0.22 + 0.12 * auraWave),
                                accent.opacity(0.06),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 8,
                            endRadius: isCompact ? 220 : 340
                        )
                    )
                    .allowsHitTesting(false)

                // Bottom-trailing secondary color mesh orb
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                secondaryOrb.opacity(0.15 + 0.11 * auraWave),
                                Color.clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 10,
                            endRadius: isCompact ? 180 : 280
                        )
                    )
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: isCompact ? 12 : 15) {
                    // Top Row: Companion Cat Stage + Title/Mood/Quote + Main Switch
                    HStack(alignment: .center, spacing: isCompact ? 12 : 16) {
                        CompanionCatStage(
                            controller: controller,
                            isCompact: isCompact
                        )

                        VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
                            // Companion mood badge + low-level disablesleep pill
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: isAwake ? "sun.max.fill" : "moon.stars.fill")
                                        .font(.system(size: isCompact ? 9.5 : 10.5, weight: .bold))
                                    Text(isAwake ? L("companion.mood.awake.badge") : L("companion.mood.sleep.badge"))
                                        .font(.system(size: isCompact ? 10 : 11, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2.5)
                                .background(
                                    Capsule()
                                        .fill(accent.opacity(0.20))
                                )
                                .foregroundStyle(accent)
                                .fixedSize(horizontal: true, vertical: false)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isAwake ? Color.orange : Color.cyan)
                                        .frame(width: 5.5, height: 5.5)
                                    Text(isAwake ? "disablesleep 1" : "disablesleep 0")
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.07))
                                )
                                .foregroundStyle(.secondary)
                                .fixedSize()
                            }

                            // Primary status headline
                            Text(isAwake ? L("hero.status.disabled") : L("hero.status.enabled"))
                                .font(.system(size: isCompact ? 16 : 21, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            // Technical subtitle
                            Text(isAwake ? L("hero.desc.disabled") : L("hero.desc.enabled"))
                                .font(.system(size: isCompact ? 11 : 12.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Main control toggle switch
                        if controller.isBusy {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 44, height: 28)
                        } else {
                            Toggle("", isOn: Binding(
                                get: { controller.isSleepDisabled },
                                set: { newValue in
                                    controller.setSleepDisabled(newValue, isAutomated: false, reasonKey: "msg.reason.hero_switch")
                                }
                            ))
                            .toggleStyle(.switch)
                            .tint(accent)
                            .labelsHidden()
                            .scaleEffect(isCompact ? 1.05 : 1.15)
                        }
                    }

                    // Interactive Companion Speech Bubble (Emotional Value Layer)
                    Button {
                        controller.petCompanion()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: isCompact ? 10.5 : 12, weight: .semibold))
                                .foregroundStyle(accent)
                                .rotationEffect(.degrees(-12))

                            Text(controller.currentCompanionQuote)
                                .font(.system(size: isCompact ? 11.5 : 12.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.92))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 4)

                            Text(L("companion.pet.hint"))
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.opacity(0.85))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(accent.opacity(0.12))
                                )
                                .fixedSize()
                        }
                        .padding(.horizontal, isCompact ? 10 : 12)
                        .padding(.vertical, isCompact ? 7 : 8)
                        .background(
                            RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                                .fill(Color.primary.opacity(0.055))
                                .overlay(
                                    RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                                        .strokeBorder(accent.opacity(0.22), lineWidth: 0.8)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .help(L("companion.pet.hint"))

                    Divider()
                        .opacity(0.45)

                    // Bottom telemetry and quick action strip
                    HStack(spacing: 8) {
                        // Power source snapshot capsule
                        Label {
                            Text(controller.powerSnapshot.formattedSummary)
                                .font(.system(size: 11.5, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
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

                        Spacer(minLength: 4)

                        // Quick toggle button
                        Button {
                            controller.toggleSleepDisabled()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: isAwake ? "moon.stars.fill" : "bolt.shield.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(isAwake ? L("hero.button.allow_sleep") : L("hero.button.disable_sleep"))
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.20))
                            )
                            .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        .disabled(controller.isBusy)
                    }
                }
                .padding(isCompact ? 14 : 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.38 + 0.24 * auraWave),
                                secondaryOrb.opacity(0.25),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            .shadow(color: accent.opacity(0.10 + 0.10 * auraWave), radius: 16, x: 0, y: 7)
        }
    }
}
