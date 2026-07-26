import SwiftUI

struct DueDatePanelView: View {
    let itemId: UUID
    let onDismiss: () -> Void
    @Environment(TodoViewModel.self) private var viewModel
    @State private var date: Date
    @State private var isAllDay: Bool
    @State private var hourStr: String
    @State private var minStr: String

    init(itemId: UUID, onDismiss: @escaping () -> Void) {
        self.itemId = itemId
        self.onDismiss = onDismiss
        let item = TodoViewModel.shared.findItem(itemId)
        let d = item?.dueDate ?? Date()
        let cal = Calendar.current
        _date = State(initialValue: d)
        _isAllDay = State(initialValue: item?.isAllDay ?? true)
        _hourStr = State(initialValue: String(format: "%02d", cal.component(.hour, from: d)))
        _minStr = State(initialValue: String(format: "%02d", cal.component(.minute, from: d)))
    }

    var body: some View {
        HStack(spacing: 0) {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .frame(width: 170).scaleEffect(0.85)
                .onChange(of: date) { _, _ in sync() }

            Divider().padding(.vertical, 6)

            VStack(spacing: 0) {
                Toggle(isOn: $isAllDay) {
                    Text("全天事件").font(.system(size: 10))
                }
                .toggleStyle(.switch)
                .onChange(of: isAllDay) { _, _ in sync() }

                Spacer()

                // 时间输入 — 始终显示，仅非全天可编辑
                HStack(spacing: 2) {
                    TextField("", text: $hourStr)
                        .frame(width: 28)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, design: .monospaced))
                        .disabled(isAllDay)
                        .onChange(of: hourStr) { _, _ in parseAndSync() }
                    Text(":").font(.system(size: 13, design: .monospaced)).foregroundColor(isAllDay ? .secondary.opacity(0.3) : .primary)
                    TextField("", text: $minStr)
                        .frame(width: 28)
                        .font(.system(size: 13, design: .monospaced))
                        .disabled(isAllDay)
                        .onChange(of: minStr) { _, _ in parseAndSync() }
                }
                .opacity(isAllDay ? 0.35 : 1)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { sync(); onDismiss() }) {
                        Text("确认").font(.system(size: 10, weight: .medium))
                            .foregroundColor(.accentColor)
                    }.buttonStyle(.plain)
                    Button(action: { viewModel.setDueDate(id: itemId, date: nil); onDismiss() }) {
                        Text("清除").font(.system(size: 9)).foregroundColor(.red.opacity(0.5))
                    }.buttonStyle(.plain)
                }
            }
            .frame(width: 100).padding(.horizontal, 8).padding(.vertical, 10)
        }
        .frame(width: 270, height: 210)
    }

    private func parseAndSync() {
        guard let h = Int(hourStr.prefix(2)), (0...23).contains(h) else { return }
        guard let m = Int(minStr.prefix(2)), (0...59).contains(m) else { return }
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        c.hour = h; c.minute = m
        if let d = Calendar.current.date(from: c) { date = d; sync() }
    }

    private func sync() {
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: date)
        if isAllDay { c.hour = 23; c.minute = 59; c.second = 59 }
        else {
            if let h = Int(hourStr.prefix(2)), (0...23).contains(h),
               let m = Int(minStr.prefix(2)), (0...59).contains(m) {
                c.hour = h; c.minute = m
            } else {
                let t = cal.dateComponents([.hour, .minute], from: date)
                c.hour = t.hour; c.minute = t.minute
            }
        }
        guard let final = cal.date(from: c) else { return }
        viewModel.setDueDateTime(id: itemId, date: final, isAllDay: isAllDay)
    }

}
