import SwiftUI

struct TodoListView: View {
    @Environment(TodoViewModel.self) private var viewModel
    @State private var showClearConfirm = false

    var body: some View {
        let theme = ThemeConfig.config(for: viewModel.theme)
        let items = viewModel.displayItems

        return VStack(spacing: 0) {
            // 操作栏（无标题，仅控制按钮）
            HStack(spacing: 6) {
                Spacer()

                if !viewModel.isSelectionMode {
                    if viewModel.hasVisibleCompletedItems() {
                        Button(action: { viewModel.showCompleted.toggle() }) {
                            Image(systemName: viewModel.showCompleted ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                                .foregroundColor(theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help(viewModel.showCompleted ? "隐藏已完成" : "显示已完成")
                    }
                    if viewModel.hasCompletedItems() {
                        Button(action: { showClearConfirm = true }) {
                            Image(systemName: "checkmark.circle.badge.xmark")
                                .font(.system(size: 12))
                                .foregroundColor(theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help("清除已完成")
                        .confirmationDialog("确认清除", isPresented: $showClearConfirm) {
                            Button("清除", role: .destructive) { viewModel.clearAllCompleted() }
                            Button("取消", role: .cancel) { }
                        } message: {
                            Text("将删除所有已完成的事项，此操作不可撤销。")
                        }
                    }
                    Button(action: { viewModel.addItem() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("添加待办事项")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            // Items list
            if items.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(theme.secondaryText.opacity(0.3))
                    Text("暂无待办")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText.opacity(0.5))
                    Text("⌘N 新建")
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText.opacity(0.3))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            TodoCardView(itemId: item.id, isSubtask: false)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
