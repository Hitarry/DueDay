import SwiftUI

extension Notification.Name {
    static let closePopoverShortcut = Notification.Name("closePopoverShortcut")
    static let openSettingsShortcut = Notification.Name("openSettingsShortcut")
    static let showShortcutsHelp = Notification.Name("showShortcutsHelp")
}

struct PopoverContentView: View {
    @Environment(TodoViewModel.self) private var viewModel
    @State private var showSettings = false
    @State private var showHelp = false

    var body: some View {
        let theme = ThemeConfig.config(for: viewModel.theme)
        let displayItems = viewModel.displayItems

        VStack(spacing: 0) {
            addCard(theme: theme)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 0) {
                    if !displayItems.isEmpty {
                        LazyVStack(spacing: 8) {
                            ForEach(displayItems) { item in
                                TodoCardView(itemId: item.id, isSubtask: false)
                                    .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("点击上方卡片或 ⌘N 添加待办")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText.opacity(0.3))
                            .padding(.top, 16)
                    }
                }
                .padding(.bottom, 8)
            }

            bottomBar(theme: theme)
        }
        .frame(width: 278, height: 450)
        .background {
            if viewModel.theme == .dark {
                Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.92)
            } else {
                Color.clear.background(.ultraThinMaterial)
            }
        }
        .background {
            Button("") { viewModel.addItem() }
                .keyboardShortcut("n", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { NotificationCenter.default.post(name: .closePopoverShortcut, object: nil) }
                .keyboardShortcut("w", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { toggleSettings() }
                .keyboardShortcut(",", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { toggleHelp() }
                .keyboardShortcut("/", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { viewModel.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { viewModel.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .opacity(0).frame(width: 0, height: 0)
        }
    }

    private func toggleSettings() {
        if showSettings { showSettings = false }
        else { showHelp = false; showSettings = true }
    }

    private func toggleHelp() {
        if showHelp { showHelp = false }
        else { showSettings = false; showHelp = true }
    }

    private func bottomBar(theme: ThemeConfig) -> some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: 6) {
                Button(action: { toggleSettings() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings, arrowEdge: .top) { SettingsView().frame(width: 280, height: 420) }

                Button(action: { toggleHelp() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showHelp, arrowEdge: .top) { helpPopoverContent }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .fill(theme.secondaryText.opacity(0.12))
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var helpPopoverContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                Text("帮助")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            Text("快捷键").font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary).padding(.top, 6).padding(.bottom, 3)
            shortcutRow("⌘Z", "撤销")
            shortcutRow("⇧⌘Z", "重做")
            shortcutRow("⌘N", "新建待办")
            shortcutRow("⌘W", "关闭弹窗")
            shortcutRow("⌘,", "设置")
            shortcutRow("⌘/", "帮助")
            .padding(.bottom, 4)

            Divider()

            Text("操作").font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary).padding(.top, 6).padding(.bottom, 3)
            tipRow("悬停卡片 → 操作按钮和倒数日")
            tipRow("右键记录 → 钉到屏幕 / 设置截止日期")
            tipRow("右键菜单栏图标 → 退出 DueDay")
            tipRow("可同时钉住多条待办到屏幕")
            tipRow("右下角齿轮 → 设置 · 问号 → 帮助")

            Divider().padding(.top, 6)
        }
        .padding(14)
        .frame(width: 230)
    }

    private func shortcutRow(_ keys: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(keys)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 48, alignment: .leading)
            Text(desc).font(.system(size: 11))
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func tipRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb")
                .font(.system(size: 9))
                .foregroundColor(.accentColor)
            Text(text).font(.system(size: 10))
            Spacer()
        }
        .padding(.vertical, 1)
    }

    private func addCard(theme: ThemeConfig) -> some View {
        Button(action: { viewModel.addItem() }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.4))
                Text("添加待办")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .fill(theme.secondaryText.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}
