import SwiftUI
import AppKit

/// Compact Haute Couture Editorial popover presented from the macOS menu bar
struct MenuBarPopoverView: View {
    @ObservedObject var controller: AppController
    @ObservedObject private var interaction = EditorialInteractionState()

    var body: some View {
        let isAwake = controller.isSleepDisabled
        let fg = EditorialTheme.foregroundColor(isAwake: isAwake)
        let hairline = EditorialTheme.hairlineColor(isAwake: isAwake)

        ZStack {
            EditorialTheme.backgroundColor(isAwake: isAwake)
                .opacity(0.92)

            VStack(spacing: 0) {
                // Top micro-header
                HStack(spacing: 8) {
                    Text(L("app.name").uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2.0)
                        .foregroundStyle(fg.opacity(0.90))
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: isAwake ? "sparkle" : "moon.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isAwake ? EditorialTheme.amberAccent : fg.opacity(0.75))

                    EditorialLanguagePill(controller: controller, isAwake: isAwake)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)

                Rectangle()
                    .fill(hairline)
                    .frame(height: 1)

                // Centerpiece editorial headline, couture cat, and micro-caption
                VStack(spacing: 12) {
                    Text(isAwake ? L("editorial.headline.awake") : L("editorial.headline.sleep"))
                        .font(EditorialTheme.headlineFont(size: 31))
                        .tracking(-0.4)
                        .foregroundStyle(fg)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.top, 14)

                    Button {
                        controller.toggleSleepDisabled()
                    } label: {
                        let assetName = isAwake ? "hero_cat_awake" : "hero_cat_sleeping"
                        Group {
                            if let nsImage = EditorialImageLoader.loadImage(named: assetName) {
                                Image(nsImage: nsImage)
                                    .renderingMode(.original)
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFit()
                                    .frame(maxHeight: isAwake ? 180 : 160)
                            } else {
                                Image(systemName: isAwake ? "cat.fill" : "cat")
                                    .font(.system(size: 80, weight: .ultraLight))
                                    .foregroundStyle(fg)
                            }
                        }
                        .scaleEffect(interaction.isCatHovered ? 1.03 : 1.0)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(controller.isBusy)
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.2)) {
                            interaction.isCatHovered = hovering
                        }
                    }

                    Text(L("editorial.popover.tap_hint"))
                        .font(.system(size: 11.5, weight: .regular))
                        .tracking(0.6)
                        .foregroundStyle(fg.opacity(0.62))
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 18)

                // Conditional subtle prompt for passwordless auth or active banner
                if controller.autoDisableOnAC && !controller.isPasswordlessConfigured {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(EditorialTheme.amberAccent)
                            .frame(width: 5.5, height: 5.5)
                        Text(L("auto.tip.passwordless"))
                            .font(.system(size: 10))
                            .foregroundStyle(fg.opacity(0.75))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Button(L("auto.tip.configure_btn")) {
                            controller.configurePasswordlessSudo()
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isAwake ? EditorialTheme.warmAlabaster : EditorialTheme.obsidianVelvet)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(fg))
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(fg.opacity(0.05))
                } else if let message = controller.bannerMessage {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(controller.isBannerError ? Color.red : EditorialTheme.amberAccent)
                            .frame(width: 5.5, height: 5.5)
                        Text(message)
                            .font(.system(size: 10.5))
                            .foregroundStyle(fg.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Button {
                            controller.clearBanner()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundStyle(fg.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(fg.opacity(0.05))
                }

                Rectangle()
                    .fill(hairline)
                    .frame(height: 1)

                // Bottom editorial control bar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Toggle("", isOn: $controller.autoDisableOnAC)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .tint(EditorialTheme.amberAccent)
                            .labelsHidden()

                        Text(L("editorial.popover.power_auto"))
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(fg.opacity(0.88))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    // Expand to Editorial Cover Window
                    Button {
                        StatusItemManager.shared.showMainWindow()
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(fg.opacity(0.75))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(fg.opacity(0.18), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(L("action.open_dashboard"))

                    // Quit app
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(fg.opacity(0.75))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(fg.opacity(0.18), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(L("action.quit"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(minWidth: 320, idealWidth: 340, maxWidth: 420)
        .animation(.easeInOut(duration: 0.3), value: isAwake)
    }
}
