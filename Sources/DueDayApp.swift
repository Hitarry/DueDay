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
    private var settingsPopover: NSPopover?
    private var helpPopover: NSPopover?
    private var pinnedWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()

        TodoViewModel.shared.onPinChanged = { [weak self] itemId in
            if let id = itemId {
                self?.showPinnedWindow(for: id)
            } else {
                self?.hidePinnedWindow()
            }
        }

        // 自动恢复上次钉住的窗口
        if let pinnedId = TodoViewModel.shared.pinnedItemId {
            TodoViewModel.shared.onPinChanged?(pinnedId)
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
        // ⌘, 设置
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettingsAction),
            name: .openSettingsShortcut,
            object: nil
        )
        // ⌘/ 帮助
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHelpAction),
            name: .showShortcutsHelp,
            object: nil
        )
    }

    @objc private func closePopover() {
        guard let popover = popover, popover.isShown else { return }
        popover.performClose(nil)
    }

    @objc private func showSettingsAction() {
        guard let button = statusItem?.button else { return }
        settingsPopover?.close()
        let hosting = NSHostingController(
            rootView: SettingsView()
                .environment(TodoViewModel.shared)
        )
        let p = NSPopover()
        p.behavior = .transient
        p.delegate = self
        p.contentViewController = hosting
        p.contentSize = NSSize(width: 320, height: 520)
        p.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        settingsPopover = p
    }

    @objc private func showHelpAction() {
        guard let button = statusItem?.button else { return }
        helpPopover?.close()
        let hosting = NSHostingController(rootView: HelpPopoverContent())
        let p = NSPopover()
        p.behavior = .transient
        p.delegate = self
        p.contentViewController = hosting
        p.contentSize = NSSize(width: 260, height: 280)
        p.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        helpPopover = p
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
            menu.addItem(NSMenuItem(title: "设置...", action: #selector(showSettingsAction), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "帮助", action: #selector(showHelpAction), keyEquivalent: "/"))
            menu.addItem(.separator())
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
        popover.contentSize = NSSize(width: 260, height: 420)
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
        hidePinnedWindow()
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

        // 测量标题文本宽度（与Do Now一致的方法）
        let title = TodoViewModel.shared.findItem(itemId)?.title ?? ""
        let tf = NSTextField(labelWithString: title)
        tf.font = .systemFont(ofSize: 14)
        let textWidth = min(max(tf.attributedStringValue.size().width, 60), 350)
        let hPad: CGFloat = 12 + 12 + 6 + 6   // innerH + outerH paddings
        let btnsW: CGFloat = 18 + 6            // vstack buttons + spacing
        let winWidth = min(max(textWidth + btnsW + hPad, 150), 420)
        let winHeight = winWidth * 0.8
        let cs = NSSize(width: winWidth, height: winHeight)
        win.contentMinSize = cs
        win.contentMaxSize = cs
        win.setContentSize(cs)

        if let saved = TodoViewModel.shared.pinnedWindowFrame {
            win.setFrameOrigin(saved.origin)
        } else if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            win.setFrameOrigin(NSPoint(x: visible.maxX - winWidth - 12, y: visible.minY + 60))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pinnedWindowDidMove),
            name: NSWindow.didMoveNotification,
            object: win
        )

        win.makeKeyAndOrderFront(nil)
        pinnedWindow = win
    }

    @objc private func pinnedWindowDidMove(_ notification: Notification) {
        guard let win = notification.object as? NSWindow else { return }
        TodoViewModel.shared.pinnedWindowFrame = win.frame
    }

    private func hidePinnedWindow() {
        if let win = pinnedWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didMoveNotification, object: win)
        }
        pinnedWindow?.close()
        pinnedWindow = nil
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldDetach(_ popover: NSPopover) -> Bool { return false }

    func popoverDidClose(_ notification: Notification) {
        if notification.object as? NSPopover == popover {
            popover?.contentViewController = nil
        }
    }
}

// MARK: - 帮助弹窗内容

struct HelpPopoverContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                Text("帮助")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.bottom, 10)

            Divider()

            Text("快捷键").font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary).padding(.top, 8).padding(.bottom, 4)
            shortcutRow("⌘Z", "撤销")
            shortcutRow("⇧⌘Z", "重做")
            shortcutRow("⌘N", "新建待办")
            shortcutRow("⌘W", "关闭弹窗")
            shortcutRow("⌘,", "设置")
            shortcutRow("⌘/", "帮助")
            .padding(.bottom, 6)

            Divider()

            Text("操作").font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary).padding(.top, 8).padding(.bottom, 4)
            tipRow("悬停卡片 → 显示操作按钮和倒数日")
            tipRow("右键记录 → 钉到屏幕 / 设置截止日期")
            tipRow("右键菜单栏 → 设置 / 退出")

            Divider().padding(.top, 8)
        }
        .padding(16)
        .frame(width: 250)
    }

    private func shortcutRow(_ keys: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 52, alignment: .leading)
            Text(desc).font(.system(size: 12))
            Spacer()
        }
        .padding(.vertical, 3)
    }

    private func tipRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
            Text(text).font(.system(size: 11))
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
