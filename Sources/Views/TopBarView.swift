import SwiftUI

struct TopBarView: View {
    @Environment(TodoViewModel.self) private var viewModel
    @State private var showSettings = false
    @State private var showShortcutsHelp = false

    var body: some View {
        HStack {
            Text("DUE DAY")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .tracking(6)

            Spacer()

            HStack(spacing: 10) {
                if viewModel.isSelectionMode {
                    HStack(spacing: 4) {
                        batchButton("完成", icon: "checkmark") {
                            viewModel.batchToggleCompleted()
                        }
                        batchButton("删除", icon: "trash", color: .red) {
                            viewModel.batchDelete()
                        }

                        Divider().frame(height: 16)

                        Button("取消") {
                            viewModel.exitSelectionMode()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(6)
                } else {
                    if !viewModel.items.isEmpty {
                        Button(action: { viewModel.isSelectionMode = true }) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("选择")
                    }

                    Button(action: { showShortcutsHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("帮助")
                    .popover(isPresented: $showShortcutsHelp) {
                        shortcutsHelpPopover
                    }

                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings) {
                        SettingsView()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsShortcut)) { _ in
            if showSettings { showSettings = false }
            else { showShortcutsHelp = false; showSettings = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showShortcutsHelp)) { _ in
            if showShortcutsHelp { showShortcutsHelp = false }
            else { showSettings = false; showShortcutsHelp = true }
        }
    }

    private var shortcutsHelpPopover: some View {
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
            VStack(spacing: 0) {
                shortcutRow("⌘Z", "撤销操作")
                shortcutRow("⇧⌘Z", "重做操作")
                shortcutRow("⌘N", "新建待办")
                shortcutRow("⌘W", "关闭弹窗")
                shortcutRow("⌘,", "打开设置")
                shortcutRow("⌘/", "打开帮助")
            }
            .padding(.bottom, 6)

            Divider()

            Text("使用技巧").font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary).padding(.top, 8).padding(.bottom, 4)
            tipRow("右键点击待办记录 → 钉到屏幕")
            tipRow("右键菜单栏图标 → 退出 DueDay")
            tipRow("右键悬浮窗口 → 开关呼吸效果")
            tipRow("悬浮窗口可拖拽移动位置")
            tipRow("点击待办 → 设置截止时间 → 自动显示倒数日")

            Divider().padding(.top, 8)
        }
        .padding(16)
        .frame(width: 280)
    }

    private func shortcutRow(_ keys: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 52, alignment: .leading)
            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 3)
    }

    private func tipRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func batchButton(_ label: String, icon: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}
