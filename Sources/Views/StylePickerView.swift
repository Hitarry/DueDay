import SwiftUI

struct StylePickerView: View {
    let itemId: UUID
    let viewModel: TodoViewModel
    var onInsertEmoji: ((String) -> Void)?

    @State private var selectedColor: String? = nil
    @State private var isBold = false
    @State private var isItalic = false
    @State private var fontSize: Double = 14
    @State private var insertTrigger = 0

    private let colors: [(String, String)] = [
        ("#000000", "黑"),("#333333", "灰1"),("#555555", "灰2"),("#777777", "灰3"),("#999999", "灰4"),("#BBBBBB", "灰5"),("#DDDDDD", "灰6"),
        ("#8B0000", "深红"),("#CC0000", "红1"),("#FF0000", "红2"),("#FF3B30", "红3"),("#FF6B6B", "浅红1"),("#FFB5B5", "浅红2"),("#FFD1DC", "浅红3"),
        ("#8B4500", "深橙"),("#CC6600", "橙1"),("#E68A00", "橙2"),("#FF9500", "橙3"),("#FFB347", "浅橙1"),("#FFCC80", "浅橙2"),("#FFD9B3", "浅橙3"),
        ("#8B7500", "深黄"),("#B89A00", "黄1"),("#FFCC00", "黄2"),("#FFE066", "浅黄1"),("#006400", "深绿"),("#34C759", "绿"),("#90EE90", "浅绿"),
        ("#00008B", "深蓝"),("#0044FF", "蓝1"),("#007AFF", "蓝2"),("#80BFFF", "浅蓝1"),("#00695C", "深青"),("#00BCD4", "青"),("#80DEEA", "浅青"),
        ("#4A007A", "深紫"),("#7B00D4", "紫1"),("#AF52DE", "紫2"),("#C47AE8", "浅紫1"),("#8B0040", "深粉"),("#FF2D55", "粉"),("#FFA8BE", "浅粉"),
        ("#3E2723", "深棕"),("#6D4C41", "棕"),("#A1887F", "浅棕"),("#D50000", "亮红"),("#FF6D00", "亮橙"),("#00C853", "亮绿"),("#2962FF", "亮蓝"),
    ]

    private let emojis = [
        "😀","😃","😄","😁","😆","😅","😂","🤣","🥲","☺️","😊","😇","🙂","🙃","😉","😌",
        "😍","🥰","😘","😗","😙","😚","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🫢","🫣",
        "🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","😮","😯","😲","😳","🥺","😢","😭",
        "😤","😠","😡","🤯","😱","😨","😰","😥",
        "👍","👎","👊","✊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","✌️","🤞","🫰","🤟",
        "🤘","🤙","👈","👉","👆","👇","🖐️","✋","💪","🦵","🦶","👀","👁️","👃","👄","🦷",
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💕","💞","💗","💖","💘","💝","💟",
        "☮️","✝️","☪️","🕉️","☸️","✡️","🔯","🪯","♈","♉","♊","♋","♌","♍","♎","♏",
        "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐸","🦁","🐮","🐷","🐒","🐔","🐧",
        "🐦","🐤","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜",
        "🌹","🌸","🌺","🌻","🌷","🌿","🍀","🌱",
        "🍎","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍑","🍒","🥑","🥦","🥕","🌽","🧀","☕",
        "🍔","🍟","🌭","🍕","🥪","🥙","🧆","🌮","🌯","🥗","🥘","🍝","🍜","🍲","🍛","🍣",
        "🥟","🍱","🍦","🍩","🍪","🎂","🍫","🍬",
        "💡","🔥","⭐️","✨","🌟","⚡","💧","🌊","🎉","🎊","🎈","🎁","🎀","🪄","🔮","💎",
        "📱","💻","⌚️","📸","🔔","📌","📍","✂️","🔑","🗝️","🔒","🔓","🔐","🛡️","⚔️","🗡️",
        "🏆","🥇","🥈","🥉","⚽","🏀","🏈","⚾",
        "✅","☑️","✔️","❌","❎","➖","➕","➗","➰","〰️","💯","🔝","🔜","🔛","🔙","🔚",
        "♻️","🆗","🆕","🆓","🆙","🆒","🆖","🔞","🛑","⛔","🚫","🚳","🚭","🚯","🚱","📵",
        "🔴","🟠","🟡","🟢","🔵","🟣","🟤","⚫",
        "🚗","🚕","🚙","🚌","🚎","🏎️","🚓","🚑","🚒","🚐","🛴","🚲","🛵","🏍️","🚨","🚔",
        "✈️","🚀","🛸","🚁","🛶","⛵","🚢","🚂",
    ]

    var body: some View {
        let _ = viewModel.items.count
        let _ = insertTrigger
        let title = viewModel.findItem(itemId)?.title ?? ""

        VStack(spacing: 0) {
            Text(title.isEmpty ? "（空）" : title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(4)
                .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: reset) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 10))
                            Text("重置样式").font(.system(size: 11))
                        }.foregroundColor(.red.opacity(0.6))
                    }.buttonStyle(.plain)

                    HStack(spacing: 10) {
                        btnBold; btnItalic
                        Spacer()
                        Stepper("字号 \(Int(fontSize))", value: $fontSize, in: 10...28, step: 1)
                            .font(.system(size: 10)).fixedSize()
                            .onChange(of: fontSize) { _, _ in syncStyle() }
                    }
                    Divider()

                    Text("颜色").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                        btnColor(nil, "A")
                        ForEach(0..<6, id: \.self) { _ in
                            Rectangle().fill(Color.clear).frame(width: 20, height: 20).allowsHitTesting(false)
                        }
                        ForEach(colors, id: \.0) { hex, _ in btnColor(hex, nil) }
                    }
                    Divider()

                    Text("表情符号（点击插入）").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: { insert(emoji) }) {
                                Text(emoji).font(.system(size: 18))
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 28)
                                    .background(Color.primary.opacity(0.04)).cornerRadius(3)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(12)
            }
        }
        .onAppear { load() }
    }

    private func btnColor(_ hex: String?, _ label: String?) -> some View {
        Button(action: { selectedColor = hex; syncStyle() }) {
            Group {
                if let l = label {
                    Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1)
                        .frame(width: 20, height: 20)
                        .overlay(Text(l).font(.system(size: 9, weight: .medium)))
                } else if let h = hex {
                    Circle().fill(colorFromHex(h)).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(selectedColor == h ? Color.primary : Color.clear, lineWidth: 1.5))
                }
            }
        }.buttonStyle(.plain)
    }

    private var btnBold: some View {
        Button(action: { isBold.toggle(); syncStyle() }) {
            Text("B").font(.system(size: 13, weight: .bold))
                .frame(width: 24, height: 22)
                .background(isBold ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                .cornerRadius(3)
        }.buttonStyle(.plain)
    }

    private var btnItalic: some View {
        Button(action: { isItalic.toggle(); syncStyle() }) {
            Text("I").font(.system(size: 13)).italic()
                .frame(width: 24, height: 22)
                .background(isItalic ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                .cornerRadius(3)
        }.buttonStyle(.plain)
    }

    private func load() {
        guard let item = viewModel.findItem(itemId) else { return }
        selectedColor = item.textColor
        isBold = item.isBold
        isItalic = item.isItalic
        fontSize = item.fontSize ?? 14
    }

    private func syncStyle() {
        viewModel.setItemStyle(id: itemId, color: selectedColor, bold: isBold, italic: isItalic, fontSize: fontSize)
    }

    private func insert(_ emoji: String) {
        if let cb = onInsertEmoji {
            cb(emoji)
        } else {
            viewModel.appendToTitle(id: itemId, text: emoji)
        }
        insertTrigger += 1
    }

    private func reset() {
        selectedColor = nil; isBold = false; isItalic = false; fontSize = 14
        syncStyle()
    }
}

func colorFromHex(_ hex: String) -> Color {
    var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
    guard h.count == 6, let int = UInt64(h, radix: 16) else { return .primary }
    return Color(
        red: Double((int >> 16) & 0xFF) / 255,
        green: Double((int >> 8) & 0xFF) / 255,
        blue: Double(int & 0xFF) / 255
    )
}
