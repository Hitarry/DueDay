import SwiftUI

struct TodoCardView: View {
    @Environment(TodoViewModel.self) private var viewModel
    let itemId: UUID
    let isSubtask: Bool
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showDeleteAlert = false
    @State private var showStylePicker = false
    @State private var showDueDatePanel = false
    @State private var showSubtaskAlert = false
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        let _ = viewModel.items.count
        let theme = ThemeConfig.config(for: viewModel.theme)
        let item = viewModel.findItem(itemId)
        let isSelected = viewModel.selectedIds.contains(itemId)
        let completed = item?.isCompleted ?? false
        let compact = !isHovered && !viewModel.isSelectionMode
        let vPad = completed ? 4.0 : (compact ? 6.0 : 10.0)

        VStack(spacing: 0) {
            HStack(spacing: 6) {
                // 展开/折叠子任务
                if !viewModel.isSelectionMode, let item = item, !item.subtasks.isEmpty {
                    Button(action: { viewModel.toggleCollapseParent(itemId) }) {
                        Image(systemName: viewModel.collapsedParentIds.contains(itemId)
                              ? "chevron.right" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: 18, height: 18)
                }
                // 完成勾选
                if !viewModel.isSelectionMode {
                    Button(action: {
                        if let it = item, !it.subtasks.isEmpty, !it.subtasks.allSatisfy(\.isCompleted), !it.isCompleted {
                            showSubtaskAlert = true
                        } else { viewModel.toggleCompleted(itemId) }
                    }) {
                        Image(systemName: completed ? "checkmark.square.fill" : "square")
                            .font(.system(size: completed ? 13 : 15))
                            .foregroundColor(completed ? .green : theme.secondaryText)
                    }.buttonStyle(.plain)
                }
                // 标题
                if isEditing && !viewModel.isSelectionMode {
                    TextField("输入待办事项...", text: $editingText)
                        .textFieldStyle(.plain).focused($isFocused)
                        .onSubmit { commitEdit() }
                        .onChange(of: isFocused) { _, v in
                            if !v && isEditing { editingText.isEmpty ? (isEditing = false) : commitEdit() }
                        }
                        .font(titleFont(item: item, compact: compact))
                        .foregroundColor(item?.textColor != nil ? colorFromHex(item!.textColor!) : theme.primaryText)
                        .onAppear { isFocused = true }
                } else {
                    Text(item?.title.isEmpty == false ? item!.title : "点击添加待办")
                        .font(titleFont(item: item, compact: compact))
                        .strikethrough(completed)
                        .foregroundColor(completed ? theme.secondaryText : (item?.textColor != nil ? colorFromHex(item!.textColor!) : theme.primaryText))
                        .opacity(completed ? 0.5 : 1.0).lineLimit(1)
                        .onTapGesture {
                            if viewModel.isSelectionMode { viewModel.toggleSelection(itemId); return }
                            editingText = item?.title ?? ""; isEditing = true
                        }
                }
                Spacer()
                // 选择模式
                if viewModel.isSelectionMode {
                    Button(action: { viewModel.toggleSelection(itemId) }) {
                        Image(systemName: isSelected ? "circle.circle.fill" : "circle")
                            .font(.system(size: 17))
                            .foregroundColor(isSelected ? .accentColor : theme.secondaryText)
                    }.buttonStyle(.plain)
                } else {
                    // 样式 + 删除 — 主视图树内（非overlay），确保popover/confirmationDialog附着稳定
                    cardButtons(theme: theme, compact: compact)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, vPad)

            // 倒数日 — hover显示
            if isHovered, !viewModel.isSelectionMode, let item = item, let dueDate = item.dueDate, !completed, !isEditing {
                Divider().padding(.horizontal, 12)
                countdownArea(dueDate: dueDate, isAllDay: item.isAllDay, theme: theme)
                    .padding(.horizontal, 12).padding(.vertical, 6)
            }
            // 子任务
            if let item = item, !item.subtasks.isEmpty, !viewModel.collapsedParentIds.contains(itemId) {
                VStack(spacing: 2) {
                    ForEach(item.subtasks) { subtask in
                        TodoCardView(itemId: subtask.id, isSubtask: true).padding(.leading, 20)
                    }
                }.padding(.bottom, 2)
            }
        }
        .background(RoundedRectangle(cornerRadius: completed ? 8 : 12)
            .fill(isSelected ? Color.accentColor.opacity(0.12) : (completed ? Color.primary.opacity(0.02) : theme.cardFill)))
        .overlay(RoundedRectangle(cornerRadius: completed ? 8 : 12)
            .stroke(completed ? Color.primary.opacity(0.04) : theme.cardStroke, lineWidth: 0.5))
        .id(itemId)
        .onHover { isHovered = $0 }
        .onTapGesture {
            if viewModel.isSelectionMode { viewModel.toggleSelection(itemId) }
        }
        .popover(isPresented: $showDueDatePanel) { DueDatePanelView(itemId: itemId, onDismiss: { showDueDatePanel = false }) }
        .contextMenu {
            if viewModel.pinnedItemIds.contains(itemId) {
                Button(action: { viewModel.unpinItem(itemId) }) { Label("取消钉到屏幕", systemImage: "pin.slash") }
            } else {
                Button(action: { viewModel.pinItem(itemId); NotificationCenter.default.post(name: .closePopoverShortcut, object: nil) }) {
                    Label("钉到屏幕", systemImage: "pin")
                }
            }
            Divider()
            Button(action: { showDueDatePanel = true }) { Label("设置截止日期", systemImage: "calendar") }
        }
        .onDisappear { if isEditing { viewModel.updateTitle(itemId, title: editingText); isEditing = false } }
        .alert("有未完成的子任务", isPresented: $showSubtaskAlert) {
            Button("确定", role: .cancel) { }
        } message: { Text("请先完成所有子任务，再标记此任务为已完成。") }
    }

    // MARK: - 右侧按钮（在主视图树内，非overlay）

    private func cardButtons(theme: ThemeConfig, compact: Bool) -> some View {
        VStack(spacing: 5) {
            Button(action: { showStylePicker = true }) {
                Image(systemName: "textformat")
                    .font(.system(size: compact ? 9 : 11))
                    .foregroundColor(theme.secondaryText)
            }
            .buttonStyle(.plain).help("文字样式")
            .popover(isPresented: $showStylePicker) {
                StylePickerView(itemId: itemId, viewModel: TodoViewModel.shared).frame(width: 260, height: 480)
            }
            if !isSubtask {
                Button(action: { viewModel.addSubtask(to: itemId) }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: compact ? 9 : 11))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain).help("添加子任务")
            }
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "trash")
                    .font(.system(size: compact ? 9 : 11))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
            }
            .buttonStyle(.plain).help("删除")
            .confirmationDialog("确认删除", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive) { viewModel.deleteItem(itemId) }
                Button("取消", role: .cancel) { }
            } message: { Text("删除后不可恢复") }
        }
        .opacity(isHovered || viewModel.isSelectionMode ? 1 : 0.25)
    }

    // MARK: - 倒数日

    private func countdownArea(dueDate: Date, isAllDay: Bool, theme: ThemeConfig) -> some View {
        let now = Date()
        let interval = dueDate.timeIntervalSince(now)
        let overdue = interval <= 0
        let total = max(0, Int(interval))
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let dateStr = dueDateFormatter.string(from: dueDate)
        return HStack(spacing: 6) {
            Image(systemName: overdue ? "exclamationmark.triangle.fill" : "timer")
                .font(.system(size: 12)).foregroundColor(overdue ? .red : .orange)
            Text("\(days)天")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(overdue ? .red : theme.primaryText)
            if !isAllDay {
                Text(String(format: "%02d:%02d", hours, minutes))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(overdue ? .red : theme.secondaryText)
            }
            if overdue { Text("已超期").font(.system(size: 10, weight: .semibold)).foregroundColor(.red) }
            Spacer()
            Text(dateStr)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.red)
        }
    }

    private var dueDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }

    private func titleFont(item: TodoItem?, compact: Bool) -> Font {
        let base: Double = (item?.isCompleted == true) ? 12 : (compact ? 13 : 14)
        let size = item?.fontSize ?? base
        var font = Font.system(size: max(size, 12))
        if item?.isBold == true { font = font.bold() }
        if item?.isItalic == true { font = font.italic() }
        return font
    }

    private func commitEdit() {
        guard !editingText.isEmpty else { isEditing = false; return }
        viewModel.updateTitle(itemId, title: editingText)
        isEditing = false
    }
}
