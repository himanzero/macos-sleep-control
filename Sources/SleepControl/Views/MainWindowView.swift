import SwiftUI
import AppKit

/// Minimalist Haute Couture Editorial Magazine Cover main window
struct MainWindowView: View {
    @ObservedObject var controller: AppController
    @ObservedObject private var interaction = EditorialInteractionState()

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let fg = EditorialTheme.foregroundColor(isAwake: isAwake)
        let hairline = EditorialTheme.hairlineColor(isAwake: isAwake)

        ZStack {
            EditorialCanvasBackdrop(isAwake: isAwake)

            HStack(spacing: 0) {
                // Left: Primary Editorial Magazine Cover (always 460pt when drawer is expanded)
                VStack(spacing: 0) {
                    // Top editorial metadata bar (traffic lights occupy top-left natively)
                    headerBar(isAwake: isAwake, fg: fg)
                        .padding(.top, 14)
                        .padding(.horizontal, 18)

                    Spacer(minLength: 14)

                    // Hero high-fashion serif headline & localized subtitle
                    VStack(spacing: 6) {
                        Text(isAwake ? L("editorial.headline.awake") : L("editorial.headline.sleep"))
                            .font(EditorialTheme.headlineFont(size: 46))
                            .tracking(-0.6)
                            .foregroundStyle(fg)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(isAwake ? L("editorial.subtitle.awake") : L("editorial.subtitle.sleep"))
                            .font(.system(size: 15, weight: .regular))
                            .tracking(1.2)
                            .foregroundStyle(fg.opacity(0.78))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 12)

                    // Centerpiece aloof & sharp couture cat (clickable to toggle sleep guard)
                    centerpieceCat(isAwake: isAwake, fg: fg)

                    Spacer(minLength: 10)

                    // Transient notification / error banner (only shown when active)
                    if let banner = controller.bannerMessage {
                        editorialBanner(banner, isAwake: isAwake, fg: fg)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                    }

                    // Bottom editorial footer strip separated by 1px hairline
                    Rectangle()
                        .fill(hairline)
                        .frame(height: 1)

                    footerBar(isAwake: isAwake, fg: fg)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                }
                .frame(minWidth: 420, idealWidth: 460, maxWidth: controller.isNerdDrawerExpanded ? 460 : .infinity)

                // Right: Expandable Nerd Diagnostic Drawer
                if controller.isNerdDrawerExpanded {
                    Rectangle()
                        .fill(hairline)
                        .frame(width: 1)
                        .ignoresSafeArea()

                    NerdDashboardView(controller: controller)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(
            minWidth: controller.isNerdDrawerExpanded ? 940 : 420,
            idealWidth: controller.isNerdDrawerExpanded ? 980 : 460,
            minHeight: 540,
            idealHeight: 590
        )
        .animation(.easeInOut(duration: 0.35), value: isAwake)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: controller.isNerdDrawerExpanded)
    }

    // MARK: - Top Metadata Bar

    private func headerBar(isAwake: Bool, fg: Color) -> some View {
        HStack(spacing: 8) {
            Spacer()

            Text(isAwake ? L("editorial.issue.awake") : L("editorial.issue.sleep"))
                .font(.system(size: 11, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(fg.opacity(0.75))
                .lineLimit(1)

            EditorialLanguagePill(controller: controller, isAwake: isAwake)

            // Discreet entry point to toggle the right-side Nerd Diagnostic Console drawer
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    controller.isNerdDrawerExpanded.toggle()
                }
            } label: {
                Image(systemName: "terminal")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(controller.isNerdDrawerExpanded ? EditorialTheme.amberAccent : fg.opacity(0.72))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(fg.opacity(controller.isNerdDrawerExpanded ? 0.12 : (isAwake ? 0.05 : 0.08)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                controller.isNerdDrawerExpanded ? EditorialTheme.amberAccent.opacity(0.65) : fg.opacity(0.18),
                                lineWidth: 0.8
                            )
                    )
            }
            .buttonStyle(.plain)
            .help(L("editorial.nerd_console.help"))
        }
    }

    // MARK: - Centerpiece Couture Cat

    private func centerpieceCat(isAwake: Bool, fg: Color) -> some View {
        let assetName = isAwake ? "hero_cat_awake" : "hero_cat_sleeping"
        let maxHeight: CGFloat = isAwake ? 265 : 235

        return TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = sin(t * (isAwake ? 1.5 : 1.0))

            Button {
                triggerCatTapFeedback()
                controller.toggleSleepDisabled()
            } label: {
                Group {
                    if let nsImage = EditorialImageLoader.loadImage(named: assetName) {
                        Image(nsImage: nsImage)
                            .renderingMode(.original)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(maxHeight: maxHeight)
                    } else {
                        Image(systemName: isAwake ? "cat.fill" : "cat")
                            .font(.system(size: 110, weight: .ultraLight))
                            .foregroundStyle(fg)
                    }
                }
                .scaleEffect(interaction.isCatPressed ? 0.96 : (interaction.isCatHovered ? 1.025 : (1.0 + 0.008 * breath)))
                .offset(y: isAwake ? (-1.5 * breath) : (1.0 * breath))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(controller.isBusy)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.22)) {
                    interaction.isCatHovered = hovering
                }
            }
            .help(isAwake ? L("editorial.pill.tap_sleep") : L("editorial.pill.tap_wake"))
        }
    }

    private func triggerCatTapFeedback() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
            interaction.isCatPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                interaction.isCatPressed = false
            }
        }
    }

    // MARK: - Transient Editorial Banner

    private func editorialBanner(_ message: String, isAwake: Bool, fg: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(controller.isBannerError ? Color.red : EditorialTheme.amberAccent)
                .frame(width: 6, height: 6)

            Text(message)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(fg.opacity(0.9))
                .lineLimit(2)

            Spacer(minLength: 4)

            Button {
                controller.clearBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(fg.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(fg.opacity(isAwake ? 0.06 : 0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(fg.opacity(0.16), lineWidth: 0.8)
        )
    }

    // MARK: - Bottom Dual-Pill Footer

    private func footerBar(isAwake: Bool, fg: Color) -> some View {
        HStack(spacing: 14) {
            // Left pill: Wake on AC Power toggle
            Button {
                controller.autoDisableOnAC.toggle()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .semibold))

                    if isAwake {
                        Text(L("editorial.pill.power_wake"))
                            .font(.system(size: 12.5, weight: .medium))
                            .lineLimit(1)
                    } else {
                        Text(controller.autoDisableOnAC ? L("editorial.pill.power_wake_on") : L("editorial.pill.power_wake_off"))
                            .font(.system(size: 12.5, weight: .medium))
                            .lineLimit(1)
                    }

                    if controller.autoDisableOnAC {
                        Circle()
                            .fill(EditorialTheme.amberAccent)
                            .frame(width: 6.5, height: 6.5)
                            .shadow(color: EditorialTheme.amberAccent.opacity(0.6), radius: 3)
                    }
                }
                .foregroundStyle(
                    (isAwake && controller.autoDisableOnAC)
                    ? EditorialTheme.warmAlabaster
                    : fg.opacity(0.88)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9.5)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(
                            isAwake
                            ? (controller.autoDisableOnAC ? EditorialTheme.espressoInk : Color.clear)
                            : Color.white.opacity(controller.autoDisableOnAC ? 0.12 : 0.06)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            fg.opacity(isAwake ? (controller.autoDisableOnAC ? 0.0 : 0.28) : 0.18),
                            lineWidth: 0.9
                        )
                )
            }
            .buttonStyle(.plain)

            // Right pill: Touch Cat to Sleep / Wake
            Button {
                triggerCatTapFeedback()
                controller.toggleSleepDisabled()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isAwake ? "sparkle" : "moon.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isAwake ? L("editorial.pill.tap_sleep") : L("editorial.pill.tap_wake"))
                        .font(.system(size: 12.5, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(fg.opacity(0.90))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9.5)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isAwake ? Color.clear : Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(fg.opacity(isAwake ? 0.28 : 0.22), lineWidth: 0.9)
                )
            }
            .buttonStyle(.plain)
            .disabled(controller.isBusy)
        }
    }
}
