import AppKit
import SwiftUI
import Combine

/// Floating frosted-glass status bar panel that automatically clamps to screen boundaries and supports user resizing and dragging
private final class StatusBarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Guarantees the panel never overflows outside the visible screen bounds
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        guard let targetScreen = screen ?? self.screen ?? NSScreen.main else {
            return super.constrainFrameRect(frameRect, to: screen)
        }
        let safeBounds = targetScreen.visibleFrame.insetBy(dx: 8, dy: 8)
        var rect = frameRect

        // Clamp dimensions if screen is smaller than rect
        rect.size.width = min(rect.size.width, safeBounds.width)
        rect.size.height = min(rect.size.height, safeBounds.height)

        // Clamp horizontal position (especially near the right edge of the screen)
        if rect.maxX > safeBounds.maxX {
            rect.origin.x = safeBounds.maxX - rect.width
        }
        if rect.minX < safeBounds.minX {
            rect.origin.x = safeBounds.minX
        }

        // Clamp vertical position
        if rect.maxY > safeBounds.maxY {
            rect.origin.y = safeBounds.maxY - rect.height
        }
        if rect.minY < safeBounds.minY {
            rect.origin.y = safeBounds.minY
        }

        return rect
    }
}

/// Manages the native AppKit status bar item, screen-adaptive control panel, and main dashboard window lifecycle
@MainActor
final class StatusItemManager: NSObject, NSWindowDelegate {
    static let shared = StatusItemManager()

    private var statusItem: NSStatusItem?
    private var statusPanel: StatusBarPanel?
    private var panelHostingView: NSHostingView<MenuBarPopoverView>?
    private var outsideClickMonitor: Any?
    private var preferredPanelWidth: CGFloat = 440
    private var mainWindow: NSWindow?
    private var controller: AppController?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
    }

    /// Sets up the status item, screen-adaptive status panel, main dashboard window, and reactive bindings with AppController
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

        configureStatusPanel(with: controller)

        // Observe sleep state changes and update icon dynamically
        controller.$isSleepDisabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isAwake in
                self?.updateIcon(isSleepDisabled: isAwake)
            }
            .store(in: &cancellables)

        // Observe language changes to update tooltip, window title, and panel layout
        controller.$appLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, let ctrl = self.controller else { return }
                self.updateIcon(isSleepDisabled: ctrl.isSleepDisabled)
                self.mainWindow?.title = L("window.main.title")
                self.adjustPanelSizeIfVisible()
            }
            .store(in: &cancellables)

        // Observe dynamic banner or automation tip changes to resize the panel smoothly
        Publishers.CombineLatest(controller.$bannerMessage, controller.$autoDisableOnAC)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.adjustPanelSizeIfVisible()
                }
            }
            .store(in: &cancellables)

        updateIcon(isSleepDisabled: controller.isSleepDisabled)
        showMainWindow()
    }

    /// Configures the resizable, draggable, frosted-glass floating control panel
    private func configureStatusPanel(with controller: AppController) {
        let initialRect = NSRect(x: 0, y: 0, width: preferredPanelWidth, height: 340)
        let panel = StatusBarPanel(
            contentRect: initialRect,
            styleMask: [.titled, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.minSize = NSSize(width: 370, height: 330)
        panel.maxSize = NSSize(width: 540, height: 640)
        panel.delegate = self

        let visualEffect = NSVisualEffectView(frame: initialRect)
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        let hostingView = NSHostingView(rootView: MenuBarPopoverView(controller: controller))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])

        panel.contentView = visualEffect
        self.panelHostingView = hostingView
        self.statusPanel = panel
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
            window.setContentSize(NSSize(width: 850, height: 830))
            window.minSize = NSSize(width: 780, height: 750)
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
        guard let closingWindow = notification.object as? NSWindow, closingWindow == mainWindow else {
            return
        }
        // Hide the Dock icon (.accessory policy) when the main dashboard window is closed while continuing background execution
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func windowDidResize(_ notification: Notification) {
        guard let resizedWindow = notification.object as? NSWindow, resizedWindow == statusPanel else {
            return
        }
        preferredPanelWidth = resizedWindow.frame.width
    }

    func windowDidResignKey(_ notification: Notification) {
        guard let resignedWindow = notification.object as? NSWindow, resignedWindow == statusPanel else {
            return
        }
        closePopover()
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
        guard let panel = statusPanel else { return }
        if panel.isVisible {
            closePopover()
        } else {
            showStatusPanel(relativeTo: sender)
        }
    }

    /// Positions the control panel below the status bar item while clamping strictly within the screen's visible boundaries
    private func showStatusPanel(relativeTo button: NSStatusBarButton) {
        guard let panel = statusPanel, let hostingView = panelHostingView else { return }

        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize

        let buttonWindow = button.window
        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let buttonScreenRect = buttonWindow?.convertToScreen(buttonRectInWindow) ?? NSRect(x: 800, y: 800, width: 22, height: 22)
        let targetScreen = buttonWindow?.screen ?? NSScreen.main
        let visibleFrame = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let safeMargin: CGFloat = 10

        let panelWidth = min(max(preferredPanelWidth, 350), min(540, visibleFrame.width - safeMargin * 2))
        let panelHeight = min(max(fitting.height, 300), visibleFrame.height - safeMargin * 2)

        // Ideal X is centered under the status bar icon; clamp strictly to [visibleFrame.minX + safeMargin, visibleFrame.maxX - panelWidth - safeMargin]
        var originX = round(buttonScreenRect.midX - panelWidth / 2.0)
        originX = max(visibleFrame.minX + safeMargin, min(originX, visibleFrame.maxX - panelWidth - safeMargin))

        // Ideal Y is 6pt below the menu bar button; clamp within visibleFrame
        var originY = round(buttonScreenRect.minY - panelHeight - 6.0)
        originY = max(visibleFrame.minY + safeMargin, min(originY, visibleFrame.maxY - panelHeight - 6.0))

        let targetFrame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
        panel.setFrame(targetFrame, display: true)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        startOutsideClickMonitor()
    }

    /// Dynamically updates panel height and screen clamping if content changes while open
    private func adjustPanelSizeIfVisible() {
        guard let panel = statusPanel, panel.isVisible, let hostingView = panelHostingView else { return }
        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize

        let currentFrame = panel.frame
        let newHeight = max(300, fitting.height)
        guard abs(newHeight - currentFrame.height) > 1 else { return }

        // Keep top edge anchored at currentFrame.maxY
        var updatedFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.maxY - newHeight,
            width: currentFrame.width,
            height: newHeight
        )
        updatedFrame = panel.constrainFrameRect(updatedFrame, to: panel.screen)
        panel.setFrame(updatedFrame, display: true, animate: true)
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func stopOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    /// Closes the status bar panel programmatically
    func closePopover() {
        stopOutsideClickMonitor()
        statusPanel?.orderOut(nil)
    }
}
