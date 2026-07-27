import SwiftUI

struct PinnedItemView: View {
    let itemId: UUID

    @Environment(TodoViewModel.self) private var viewModel
    @State private var breathOpacity: Double = 1.0

    var body: some View {
        let theme = ThemeConfig.config(for: viewModel.theme)
        let item = viewModel.findItem(itemId)

        VStack(spacing: 0) {
            // 行1：竖排按钮 + 标题
            HStack(spacing: 6) {
                VStack(spacing: 2) {
                    Button(action: { viewModel.unpinItem(itemId) }) {
                        ZStack {
                            Circle().fill(Color.primary.opacity(0.10)).frame(width: 18, height: 18)
                            Image(systemName: "pin.slash").font(.system(size: 10)).foregroundColor(theme.secondaryText)
                        }
                    }.buttonStyle(.plain).help("取消钉住")
                    Button(action: { viewModel.toggleCompleted(itemId); viewModel.unpinItem(itemId) }) {
                        Image(systemName: item?.isCompleted == true ? "checkmark.square.fill" : "square")
                            .font(.system(size: 15))
                            .foregroundColor(item?.isCompleted == true ? .green : theme.secondaryText)
                    }.buttonStyle(.plain)
                }
                Text(item?.title.isEmpty == false ? item!.title : "（无标题）")
                    .font(pinDisplayFont(item: item))
                    .strikethrough(item?.isCompleted ?? false)
                    .foregroundColor(item?.isCompleted == true ? theme.secondaryText
                        : (item?.textColor).flatMap { colorFromHex($0) } ?? theme.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: true, vertical: false)
                    .opacity(viewModel.isPinnedBreathingEnabled ? breathOpacity : 1.0)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.top, 10)

            // 行2+3：倒数日
            if let item = item, let dueDate = item.dueDate {
                Divider().padding(.horizontal, 12).padding(.vertical, 4)
                countdownSection(dueDate: dueDate, isAllDay: item.isAllDay, theme: theme)
            }
        }
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(viewModel.theme == .dark ? Color.black.opacity(0.65) : Color.white.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        .padding(6)
        .onAppear { startBreathingIfEnabled() }
        .onChange(of: viewModel.isPinnedBreathingEnabled) { _, e in
            e ? startBreathingIfEnabled() : withAnimation(nil) { breathOpacity = 1.0 }
        }
        .contextMenu {
            if viewModel.isPinnedBreathingEnabled {
                Button(action: { viewModel.isPinnedBreathingEnabled = false }) { Label("呼吸效果", systemImage: "checkmark") }
            } else {
                Button(action: { viewModel.isPinnedBreathingEnabled = true }) { Text("呼吸效果") }
            }
        }
    }

    private func countdownSection(dueDate: Date, isAllDay: Bool, theme: ThemeConfig) -> some View {
        let interval = dueDate.timeIntervalSinceNow
        let overdue = interval <= 0
        let total = max(0, Int(interval))
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                if overdue {
                    Text("-")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.red).fixedSize()
                } else {
                    Text("\(days)")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.primaryText).fixedSize()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)

            if !isAllDay && !overdue {
                HStack(spacing: 0) {
                    Text(String(format: "%02d:%02d", hours, minutes))
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.secondaryText).fixedSize()
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12).padding(.top, 2)
            }
        }
        .padding(.bottom, 8)
    }

    private func startBreathingIfEnabled() {
        guard viewModel.isPinnedBreathingEnabled else { return }
        breathOpacity = 1.0
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathOpacity = 0.6 }
    }

    private func pinDisplayFont(item: TodoItem?) -> Font {
        let size = item?.fontSize ?? 13
        var font = Font.system(size: max(size, 13))
        if item?.isBold == true { font = font.bold() }
        if item?.isItalic == true { font = font.italic() }
        return font
    }
}
