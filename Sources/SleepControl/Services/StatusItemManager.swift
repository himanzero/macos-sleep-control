import AppKit
import SwiftUI
import Combine

/// Manages the native AppKit status bar item, frosted glass popover panel, and main dashboard window lifecycle
@MainActor
final class StatusItemManager: NSObject, NSWindowDelegate {
    static let shared = StatusItemManager()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var controller: AppController?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
    }

    /// Sets up the status item, main dashboard window, and reactive bindings with AppController
    func setup(with controller: AppController) {
        self.controller = controller

        // Use squareLength (22pt) to occupy minimal width on crowded status bars (especially with camera notches)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "com.himanzero.SleepControl.StatusItem"
        self.statusItem = item

        if let button = item.button {
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Configure transient frosted popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView(controller: controller))
        self.popover = popover

        // Observe sleep state changes and update icon dynamically
        controller.$isSleepDisabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isAwake in
                self?.updateIcon(isSleepDisabled: isAwake)
            }
            .store(in: &cancellables)

        // Observe language changes to update tooltip and window title
        controller.$appLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, let ctrl = self.controller else { return }
                self.updateIcon(isSleepDisabled: ctrl.isSleepDisabled)
                self.mainWindow?.title = L("window.main.title")
            }
            .store(in: &cancellables)

        updateIcon(isSleepDisabled: controller.isSleepDisabled)
        showMainWindow()
    }

    /// Creates (if needed) and brings the main dashboard window to the front, restoring the Dock icon (.regular policy)
    func showMainWindow() {
        closePopover()
        NSApp.setActivationPolicy(.regular)

        if mainWindow == nil, let controller = self.controller {
            let hostingController = NSHostingController(rootView: MainWindowView(controller: controller))
            let window = NSWindow(contentViewController: hostingController)
            window.identifier = NSUserInterfaceItemIdentifier("main-window")
            window.title = L("window.main.title")
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isRestorable = false
            // Preserve the window instance when the user clicks the close ('x') button so it can be re-shown anytime
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setContentSize(NSSize(width: 840, height: 790))
            window.minSize = NSSize(width: 780, height: 720)
            window.center()
            self.mainWindow = window
        }

        guard let window = mainWindow else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Hide the Dock icon (.accessory policy) when the main dashboard window is closed while continuing background execution
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// Updates status bar button icon and tooltip based on active sleep state
    private func updateIcon(isSleepDisabled: Bool) {
        guard let button = statusItem?.button else { return }

        let iconName = isSleepDisabled ? "status_cat_awake" : "status_cat_sleeping"
        if let bundleImage = Bundle.main.image(forResource: iconName) {
            bundleImage.isTemplate = true
            bundleImage.size = NSSize(width: 18, height: 18)
            button.image = bundleImage
        } else if let resourcePath = Bundle.main.path(forResource: iconName, ofType: "png"),
                  let fileImage = NSImage(contentsOfFile: resourcePath) {
            fileImage.isTemplate = true
            fileImage.size = NSSize(width: 18, height: 18)
            button.image = fileImage
        } else {
            // Fallback to SF Symbol
            let fallbackSymbol = isSleepDisabled ? "cat" : "cat.fill"
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            let image = NSImage(systemSymbolName: fallbackSymbol, accessibilityDescription: "SleepControl")?
                .withSymbolConfiguration(config)
            image?.isTemplate = true
            button.image = image
        }

        button.toolTip = isSleepDisabled ? L("hero.status.disabled") : L("hero.status.enabled")
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let popover = popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    /// Closes the popover programmatically
    func closePopover() {
        popover?.performClose(nil)
    }
}
