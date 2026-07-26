import SwiftUI

extension Notification.Name {
    static let closePopoverShortcut = Notification.Name("closePopoverShortcut")
    static let openSettingsShortcut = Notification.Name("openSettingsShortcut")
    static let showShortcutsHelp = Notification.Name("showShortcutsHelp")
}

struct PopoverContentView: View {
    @Environment(TodoViewModel.self) private var viewModel

    var body: some View {
        let theme = ThemeConfig.config(for: viewModel.theme)
        let displayItems = viewModel.displayItems

        ScrollView {
            VStack(spacing: 0) {
                // 顶部添加卡片（始终存在）
                addCard(theme: theme)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                // 待办事项列表
                if !displayItems.isEmpty {
                    LazyVStack(spacing: 8) {
                        ForEach(displayItems) { item in
                            TodoCardView(itemId: item.id, isSubtask: false)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    // 空状态提示
                    Text("点击上方卡片或 ⌘N 添加待办")
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText.opacity(0.3))
                        .padding(.top, 16)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 260, height: 420)
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
            Button("") { NotificationCenter.default.post(name: .openSettingsShortcut, object: nil) }
                .keyboardShortcut(",", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        }
        .background {
            Button("") { NotificationCenter.default.post(name: .showShortcutsHelp, object: nil) }
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

    private func addCard(theme: ThemeConfig) -> some View {
        Button(action: { viewModel.addItem() }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.4))
                Text("添加待办")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .fill(theme.secondaryText.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}
