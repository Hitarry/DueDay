import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var isSubtask: Bool = false
    var subtasks: [TodoItem] = []
    var createdAt: Date = Date()

    // 截止时间
    var dueDate: Date?
    var isAllDay: Bool = true  // 全天事件，仅设日期不设时刻

    // 文字样式
    var textColor: String?
    var isBold: Bool = false
    var isItalic: Bool = false
    var fontSize: Double?
}
