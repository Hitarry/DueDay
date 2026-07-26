import Foundation

func countdownDays(from dueDate: Date) -> Int {
    let now = Date()
    let interval = dueDate.timeIntervalSince(now)
    guard interval > 0 else { return 0 }
    return Int(interval) / 86400
}

func countdownTimeString(from dueDate: Date) -> String {
    let now = Date()
    let interval = dueDate.timeIntervalSince(now)
    guard interval > 0 else { return "00:00:00" }

    let total = Int(interval)
    let hours = (total % 86400) / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func countdownDetailText(from dueDate: Date) -> String {
    let now = Date()
    let interval = dueDate.timeIntervalSince(now)
    guard interval > 0 else { return "已到期" }

    let total = Int(interval)
    let days = total / 86400
    let hours = (total % 86400) / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    if days > 0 {
        return "\(days)天 \(hours)小时 \(minutes)分 \(seconds)秒"
    } else if hours > 0 {
        return "\(hours)小时 \(minutes)分 \(seconds)秒"
    } else {
        return "\(minutes)分 \(seconds)秒"
    }
}

func isOverdue(_ dueDate: Date) -> Bool {
    dueDate.timeIntervalSinceNow <= 0
}
