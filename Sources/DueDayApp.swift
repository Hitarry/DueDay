import SwiftUI

@main
struct DueDayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        _ = TodoViewModel.shared
    }

    var body: some Scene {
        Settings { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var pinnedWindows: [UUID: NSWindow] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()

        TodoViewModel.shared.onPinChanged = { [weak self] itemId, isPin in
            if isPin {
                self?.showPinnedWindow(for: itemId)
            } else {
                self?.hidePinnedWindow(for: itemId)
            }
        }

        // 自动恢复上次钉住的窗口
        for pinnedId in TodoViewModel.shared.pinnedItemIds {
            TodoViewModel.shared.onPinChanged?(pinnedId, true)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: .closePopoverShortcut,
            object: nil
        )
    }

    @objc private func closePopover() {
        guard let popover = popover, popover.isShown else { return }
        popover.performClose(nil)
    }

    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: -1)
        self.statusItem = item

        if let button = item.button {
            let image = generateMenuBarIcon()
            image.isTemplate = true
            button.image = image
            button.image?.size = NSSize(width: 20, height: 20)
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let p = NSPopover()
        p.behavior = .transient
        p.delegate = self
        self.popover = p
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "退出 DueDay", action: #selector(quitApp), keyEquivalent: "q"))
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
        } else {
            togglePopover()
        }
    }

    private func generateMenuBarIcon() -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(x: 1, y: 1, width: 20, height: 20)
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
        bgPath.fill()
        NSColor.controlAccentColor.withAlphaComponent(0.35).setStroke()
        bgPath.lineWidth = 1.5
        bgPath.stroke()

        let center = NSPoint(x: 11, y: 11)
        let clockPath = NSBezierPath()
        clockPath.appendArc(withCenter: center, radius: 7, startAngle: 0, endAngle: 360)
        NSColor.controlAccentColor.withAlphaComponent(0.8).setStroke()
        clockPath.lineWidth = 1.5
        clockPath.stroke()

        let minHand = NSBezierPath()
        minHand.move(to: center)
        minHand.line(to: NSPoint(x: center.x, y: center.y + 5))
        minHand.lineWidth = 1.2
        minHand.stroke()

        let hourHand = NSBezierPath()
        hourHand.move(to: center)
        hourHand.line(to: NSPoint(x: center.x + 3, y: center.y + 3))
        hourHand.lineWidth = 2
        hourHand.stroke()

        image.unlockFocus()
        return image
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environment(TodoViewModel.shared)
        )
        popover.contentSize = NSSize(width: 278, height: 450)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if let window = popover.contentViewController?.view.window {
            window.makeKey()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    // MARK: - 浮动窗口（钉到屏幕）

    private func showPinnedWindow(for itemId: UUID) {
        guard pinnedWindows[itemId] == nil else { return }
        let hosting = NSHostingController(
            rootView: PinnedItemView(itemId: itemId)
                .environment(TodoViewModel.shared)
        )
        let win = NSWindow(contentViewController: hosting)
        win.styleMask = [.fullSizeContentView]
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let title = TodoViewModel.shared.findItem(itemId)?.title ?? ""
        let tf = NSTextField(labelWithString: title)
        tf.font = .systemFont(ofSize: 14)
        let textWidth = min(max(tf.attributedStringValue.size().width, 60), 350)
        let hPad: CGFloat = 12 + 12 + 6 + 6
        let btnsW: CGFloat = 18 + 6
        let winWidth = min(max(textWidth + btnsW + hPad, 150), 420)
        let winHeight = winWidth * 0.8
        let cs = NSSize(width: winWidth, height: winHeight)
        win.contentMinSize = cs
        win.contentMaxSize = cs
        win.setContentSize(cs)

        if let saved = TodoViewModel.shared.pinnedWindowFrames[itemId] {
            win.setFrameOrigin(saved.origin)
        } else if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let offset = CGFloat(pinnedWindows.count) * 20
            win.setFrameOrigin(NSPoint(x: visible.maxX - winWidth - 12, y: visible.minY + 60 + offset))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pinnedWindowDidMove),
            name: NSWindow.didMoveNotification,
            object: win
        )

        win.makeKeyAndOrderFront(nil)
        pinnedWindows[itemId] = win
    }

    @objc private func pinnedWindowDidMove(_ notification: Notification) {
        guard let win = notification.object as? NSWindow else { return }
        for (itemId, w) in pinnedWindows where w === win {
            var frames = TodoViewModel.shared.pinnedWindowFrames
            frames[itemId] = win.frame
            TodoViewModel.shared.pinnedWindowFrames = frames
            break
        }
    }

    private func hidePinnedWindow(for itemId: UUID) {
        guard let win = pinnedWindows[itemId] else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.didMoveNotification, object: win)
        win.close()
        pinnedWindows.removeValue(forKey: itemId)
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool { return false }

    func popoverDidClose(_ notification: Notification) {
        if notification.object as? NSPopover == popover {
            popover?.contentViewController = nil
        }
    }
}
