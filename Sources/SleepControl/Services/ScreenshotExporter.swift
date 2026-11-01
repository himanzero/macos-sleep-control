import AppKit
import SwiftUI

/// Exports high-resolution Retina screenshots of the application views using native AppKit NSWindow caching
@MainActor
enum ScreenshotExporter {
    static func exportAll(to directoryPath: String, controller: AppController) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

        let originalLang = controller.appLanguage

        // 1. Export English Dashboard & Popover
        controller.selectLanguage(.en)
        exportWindowSnapshot(
            rootView: MainWindowView(controller: controller).environment(\.colorScheme, .dark),
            size: NSSize(width: 840, height: 830),
            to: "\(directoryPath)/dashboard_en.png"
        )
        exportWindowSnapshot(
            rootView: MenuBarPopoverView(controller: controller)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .dark),
            size: NSSize(width: 420, height: 340),
            to: "\(directoryPath)/menubar_popover_en.png"
        )

        // 2. Export Simplified Chinese Dashboard & Popover
        controller.selectLanguage(.zhHans)
        exportWindowSnapshot(
            rootView: MainWindowView(controller: controller).environment(\.colorScheme, .dark),
            size: NSSize(width: 840, height: 830),
            to: "\(directoryPath)/dashboard_zh.png"
        )
        exportWindowSnapshot(
            rootView: MenuBarPopoverView(controller: controller)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .dark),
            size: NSSize(width: 420, height: 340),
            to: "\(directoryPath)/menubar_popover_zh.png"
        )

        // Restore original language preference
        controller.selectLanguage(originalLang)
    }

    private static func exportWindowSnapshot<V: View>(rootView: V, size: NSSize, to filePath: String) {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = hostingView
        window.setContentSize(size)

        // Layout and pump runloop briefly so AppKit controls (Toggle, Menu, ScrollView) finish rendering
        hostingView.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        hostingView.layoutSubtreeIfNeeded()

        let bounds = hostingView.bounds
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return
        }
        hostingView.cacheDisplay(in: bounds, to: bitmapRep)

        if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: filePath))
        }
        window.orderOut(nil)
    }
}
