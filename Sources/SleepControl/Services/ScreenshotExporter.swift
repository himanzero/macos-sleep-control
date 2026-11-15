import AppKit
import SwiftUI

/// Exports high-resolution Retina screenshots of the application views using native AppKit NSWindow caching
@MainActor
enum ScreenshotExporter {
    static func exportAll(to directoryPath: String, controller: AppController) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

        let originalLang = controller.appLanguage
        let originalSleepDisabled = controller.isSleepDisabled
        let originalDrawer = controller.isNerdDrawerExpanded

        // 1. Export English Editorial Main Window (Awake & Sleeping), Expanded Nerd Drawer, and Popovers
        controller.selectLanguage(.en)

        controller.setScreenshotPreviewSleepDisabled(true)
        controller.isNerdDrawerExpanded = false
        exportWindowSnapshot(
            rootView: MainWindowView(controller: controller),
            size: NSSize(width: 460, height: 590),
            to: "\(directoryPath)/dashboard_en.png",
            appearance: .aqua
        )
        exportWindowSnapshot(
            rootView: MenuBarPopoverView(controller: controller),
            size: NSSize(width: 340, height: 420),
            to: "\(directoryPath)/menubar_popover_en.png",
            appearance: .aqua
        )
        controller.isNerdDrawerExpanded = true
        exportWindowSnapshot(
            rootView: MainWindowView(controller: controller),
            size: NSSize(width: 980, height: 590),
            to: "\(directoryPath)/dashboard_nerd_en.png",
            appearance: .aqua
        )

        controller.setScreenshotPreviewSleepDisabled(false)
        controller.isNerdDrawerExpanded = false
        exportWindowSnapshot(
            rootView: MainWindowView(controller: controller),
            size: NSSize(width: 460, height: 590),
            to: "\(directoryPath)/dashboard_sleeping_en.png",
            appearance: .darkAqua
        )
        exportWindowSnapshot(
            rootView: MenuBarPopoverView(controller: controller),
            size: NSSize(width: 340, height: 420),
            to: "\(directoryPath)/menubar_popover_sleeping_en.png",
            appearance: .darkAqua
        )

        // Restore original state & language preference
        controller.setScreenshotPreviewSleepDisabled(originalSleepDisabled)
        controller.isNerdDrawerExpanded = originalDrawer
        controller.selectLanguage(originalLang)
    }

    private static func exportWindowSnapshot<V: View>(
        rootView: V,
        size: NSSize,
        to filePath: String,
        appearance: NSAppearance.Name
    ) {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: appearance)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = hostingView
        window.setContentSize(size)

        // Layout and pump runloop briefly so AppKit controls (Toggle, Menu, ScrollView) finish rendering
        hostingView.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.18))
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
