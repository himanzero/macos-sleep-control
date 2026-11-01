import SwiftUI
import AppKit

/// Main application entry point and delegate managing status item, main menu, and window reopen lifecycle
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--export-screenshots"), idx + 1 < args.count {
            let outputDir = args[idx + 1]
            ScreenshotExporter.exportAll(to: outputDir, controller: AppController.shared)
            NSApp.terminate(nil)
            return
        }

        NSWindow.allowsAutomaticWindowTabbing = false
        setupMainMenu()
        StatusItemManager.shared.setup(with: AppController.shared)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running in the status bar and Dock when the dashboard window is closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Always summon the main dashboard window when clicking the Dock icon or double-clicking SleepControl.app in Finder
        StatusItemManager.shared.showMainWindow()
        return true
    }

    /// Configures standard macOS application and window menus (supporting Cmd+W, Cmd+0, Cmd+Q)
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. Application Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let showItem = NSMenuItem(
            title: L("window.main.title"),
            action: #selector(handleShowMainWindow),
            keyEquivalent: "0"
        )
        showItem.target = self
        appMenu.addItem(showItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "\(L("action.quit")) SleepControl",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        // 2. Window Menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu

        let closeItem = NSMenuItem(
            title: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        windowMenu.addItem(closeItem)

        let minimizeItem = NSMenuItem(
            title: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        windowMenu.addItem(minimizeItem)

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    @objc private func handleShowMainWindow() {
        StatusItemManager.shared.showMainWindow()
    }
}
