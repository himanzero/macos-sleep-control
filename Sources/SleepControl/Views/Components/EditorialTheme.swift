import SwiftUI
import AppKit

/// Haute Couture Editorial Chic palette, typography, and shared UI primitives
enum EditorialTheme {
    /// Warm Alabaster paper background for Awake state (#F5F1E8)
    static let warmAlabaster = Color(red: 245.0 / 255.0, green: 241.0 / 255.0, blue: 232.0 / 255.0)
    /// Deep Espresso ink foreground for Awake state (#1A1917)
    static let espressoInk = Color(red: 26.0 / 255.0, green: 25.0 / 255.0, blue: 23.0 / 255.0)
    /// Deep Obsidian velvet background for Sleeping state (#111216)
    static let obsidianVelvet = Color(red: 17.0 / 255.0, green: 18.0 / 255.0, blue: 22.0 / 255.0)
    /// Warm Ivory silk foreground for Sleeping state (#F2EFE9)
    static let ivorySilk = Color(red: 242.0 / 255.0, green: 239.0 / 255.0, blue: 233.0 / 255.0)
    /// Champagne-amber accent dot (#E59A3C)
    static let amberAccent = Color(red: 229.0 / 255.0, green: 154.0 / 255.0, blue: 60.0 / 255.0)

    static func backgroundColor(isAwake: Bool) -> Color {
        isAwake ? warmAlabaster : obsidianVelvet
    }

    static func foregroundColor(isAwake: Bool) -> Color {
        isAwake ? espressoInk : ivorySilk
    }

    static func hairlineColor(isAwake: Bool) -> Color {
        foregroundColor(isAwake: isAwake).opacity(isAwake ? 0.14 : 0.15)
    }

    /// Editorial serif headline font (Didot / fallback system serif)
    static func headlineFont(size: CGFloat) -> Font {
        if NSFont(name: "Didot-Bold", size: size) != nil {
            return Font.custom("Didot-Bold", size: size)
        }
        return Font.system(size: size, weight: .bold, design: .serif)
    }
}

/// Observable micro-interaction state for editorial views (avoids SwiftUIMacros @State dependency under CLT)
final class EditorialInteractionState: ObservableObject {
    @Published var isCatHovered: Bool = false
    @Published var isCatPressed: Bool = false
    /// Normalized cursor parallax offset (-1...1)
    @Published var parallaxPoint: CGPoint = .zero
    /// Normalized origin for circular iris theme transitions
    @Published var irisOrigin: UnitPoint = .center
    /// Progress (0...1) for circular iris theme transitions
    @Published var irisProgress: CGFloat = 1.0
    /// Incrementing trigger for ambient halo pulse effects
    @Published var haloPulseTrigger: Int = 0
}

/// Editorial hairline-bordered card container matching the main cover's Awake/Sleeping palette
struct EditorialSectionCard<Content: View>: View {
    let isAwake: Bool
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        let fg = EditorialTheme.foregroundColor(isAwake: isAwake)
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fg.opacity(isAwake ? 0.035 : 0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(EditorialTheme.hairlineColor(isAwake: isAwake), lineWidth: 0.9)
            )
    }
}

/// Multi-tier image loader for editorial cat assets across .app bundle and SwiftPM test/dev runs
enum EditorialImageLoader {
    static func loadImage(named name: String) -> NSImage? {
        if let named = NSImage(named: name) {
            return named
        }
        if let resImg = Bundle.main.image(forResource: name) {
            return resImg
        }
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let fileImg = NSImage(contentsOfFile: path) {
            return fileImg
        }
        let localCandidates = [
            "Resources/\(name)@2x.png",
            "Resources/\(name).png"
        ]
        for candidate in localCandidates {
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(candidate)
            if let img = NSImage(contentsOf: url) {
                return img
            }
        }
        return nil
    }
}

/// Editorial paper/velvet backdrop with subtle radial luminescence behind the centerpiece cat
struct EditorialCanvasBackdrop: View {
    let isAwake: Bool

    var body: some View {
        ZStack {
            EditorialTheme.backgroundColor(isAwake: isAwake)

            // Subtle ambient glow behind the cat centerpiece
            RadialGradient(
                colors: isAwake
                    ? [
                        Color(red: 0.94, green: 0.85, blue: 0.68).opacity(0.32),
                        Color.clear
                    ]
                    : [
                        Color(red: 0.20, green: 0.24, blue: 0.42).opacity(0.28),
                        Color.clear
                    ],
                center: UnitPoint(x: 0.5, y: 0.54),
                startRadius: 10,
                endRadius: 260
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: isAwake)
    }
}

/// Minimal 1px-bordered editorial language switcher pill ("简" / "EN" / etc.)
struct EditorialLanguagePill: View {
    @ObservedObject var controller: AppController
    let isAwake: Bool

    var body: some View {
        let fg = EditorialTheme.foregroundColor(isAwake: isAwake)

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
            Text(controller.appLanguage.shortBadgeCode)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(fg.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(fg.opacity(isAwake ? 0.06 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(fg.opacity(0.18), lineWidth: 0.8)
                )
        }
        .menuStyle(.borderlessButton)
        .environment(\.colorScheme, isAwake ? .light : .dark)
        .fixedSize()
        .help(L("lang.menu.title"))
    }
}

/// Animatable circular iris reveal shape expanding from an arbitrary normalized origin to cover the full bounds
struct CircularIrisShape: Shape {
    var progress: CGFloat
    var origin: UnitPoint = .center

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = max(0, min(1, progress))
        let center = CGPoint(
            x: rect.minX + rect.width * origin.x,
            y: rect.minY + rect.height * origin.y
        )
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        let maxRadius = corners.reduce(CGFloat(0)) { currentMax, corner in
            max(currentMax, hypot(corner.x - center.x, corner.y - center.y))
        }
        let radius = maxRadius * clamped

        var path = Path()
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }
}

private final class LiquidIndicatorDotState: ObservableObject {
    @Published var rippleScale: CGFloat = 1.0
    @Published var rippleOpacity: Double = 0.0
}

/// Liquid-like status indicator dot with spring pop-in and subtle expanding ripple halo when activated
struct LiquidIndicatorDot: View {
    let isActive: Bool
    var color: Color = EditorialTheme.amberAccent
    var size: CGFloat = 6
    var pulseTrigger: Int = 0

    @StateObject private var state = LiquidIndicatorDotState()

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(state.rippleOpacity), lineWidth: 1.2)
                .frame(width: size, height: size)
                .scaleEffect(state.rippleScale)
                .allowsHitTesting(false)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(isActive ? 1.0 : 0.2)
                .opacity(isActive ? 1.0 : 0.0)
                .animation(.spring(response: 0.34, dampingFraction: 0.56), value: isActive)
        }
        .frame(width: size, height: size)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerRipple()
            }
        }
        .onChange(of: pulseTrigger) { _, _ in
            if isActive {
                triggerRipple()
            }
        }
    }

    private func triggerRipple() {
        state.rippleScale = 1.0
        state.rippleOpacity = 0.7
        withAnimation(.easeOut(duration: 0.65)) {
            state.rippleScale = 2.8
            state.rippleOpacity = 0.0
        }
    }
}
