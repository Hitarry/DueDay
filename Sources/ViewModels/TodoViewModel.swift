import Foundation
import Observation

@Observable
final class TodoViewModel {
    var items: [TodoItem] = []
    var theme: ThemeType = .system
    var draggedItemId: UUID?
    var collapsedParentIds: Set<UUID> = []
    var showCompleted = true
    var sortStamp = 0  // 每次items变更时递增，强制视图刷新排序
    var pinnedItemIds: Set<UUID> = [] {
        didSet {
            let arr = pinnedItemIds.map { $0.uuidString }
            UserDefaults.standard.set(arr, forKey: "pinnedItemIds")
            let removed = oldValue.subtracting(pinnedItemIds)
            for id in removed { onPinChanged?(id, false) }
            let added = pinnedItemIds.subtracting(oldValue)
            for id in added { onPinChanged?(id, true) }
        }
    }

    // 撤销/重做
    private var undoStack: [[TodoItem]] = []
    private var redoStack: [[TodoItem]] = []
    private let maxUndoStack = 50
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // 浮动窗口位置（每个钉住项独立）
    var pinnedWindowFrames: [UUID: NSRect] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "pinnedWindowFrames"),
                  let dict = try? JSONDecoder().decode([String: [Double]].self, from: data)
            else { return [:] }
            var result: [UUID: NSRect] = [:]
            for (key, arr) in dict where arr.count == 4 {
                guard let id = UUID(uuidString: key), arr[2] > 0, arr[3] > 0 else { continue }
                result[id] = NSRect(x: arr[0], y: arr[1], width: arr[2], height: arr[3])
            }
            return result
        }
        set {
            let dict = Dictionary(uniqueKeysWithValues: newValue.map { kv in
                (kv.key.uuidString, [kv.value.origin.x, kv.value.origin.y, kv.value.size.width, kv.value.size.height])
            })
            if let data = try? JSONEncoder().encode(dict) {
                UserDefaults.standard.set(data, forKey: "pinnedWindowFrames")
            }
        }
    }

    static let shared = TodoViewModel()

    private let saveFile: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dataDir = appSupport.appendingPathComponent("DueDay", isDirectory: true)
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        saveFile = dataDir.appendingPathComponent("todos.json")

        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = ThemeType(rawValue: savedTheme) {
            self.theme = theme
        }

        loadItems()

        // 恢复上次钉住的记录
        if let arr = UserDefaults.standard.stringArray(forKey: "pinnedItemIds") {
            pinnedItemIds = Set(arr.compactMap { UUID(uuidString: $0) }.filter { findItem($0) != nil })
        }
    }

    // MARK: - Items

    func effectiveDueDate(_ item: TodoItem) -> Date? {
        var dates = item.subtasks.compactMap { $0.dueDate }
        if let d = item.dueDate { dates.append(d) }
        return dates.min()
    }

    var topLevelItems: [TodoItem] {
        items
            .filter { !$0.isSubtask }
            .sorted { a, b in
                if a.isCompleted != b.isCompleted { return !a.isCompleted }
                let aDue = effectiveDueDate(a)
                let bDue = effectiveDueDate(b)
                if aDue == nil && bDue != nil { return true }
                if aDue != nil && bDue == nil { return false }
                if let aD = aDue, let bD = bDue { return aD < bD }
                return a.createdAt > b.createdAt
            }
    }

    var displayItems: [TodoItem] {
        if showCompleted {
            return topLevelItems
        }
        return topLevelItems.filter { !$0.isCompleted }
    }

    // MARK: - Theme

    func setTheme(_ theme: ThemeType) {
        self.theme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }

    // MARK: - Completed

    func hasCompletedItems() -> Bool {
        items.contains { $0.isCompleted && !$0.isSubtask }
    }

    func hasVisibleCompletedItems() -> Bool {
        displayItems.contains { $0.isCompleted }
    }

    func toggleCollapseParent(_ id: UUID) {
        if collapsedParentIds.contains(id) {
            collapsedParentIds.remove(id)
        } else {
            collapsedParentIds.insert(id)
        }
    }

    func clearAllCompleted() {
        pushUndo()
        var copy = items
        let ids = copy.filter { $0.isCompleted && !$0.isSubtask }.map { $0.id }
        copy.removeAll { ids.contains($0.id) }
        items = copy
        saveItems()
    }

    // MARK: - Item Lookup

    private func findItemIndex(_ id: UUID) -> (parentIndex: Int?, childIndex: Int?) {
        for (i, item) in items.enumerated() {
            if item.id == id { return (nil, i) }
            for (j, subtask) in item.subtasks.enumerated() {
                if subtask.id == id { return (i, j) }
            }
        }
        return (nil, nil)
    }

    func findItem(_ id: UUID) -> TodoItem? {
        for item in items {
            if item.id == id { return item }
            if let subtask = item.subtasks.first(where: { $0.id == id }) { return subtask }
        }
        return nil
    }

    // MARK: - 撤销/重做

    private func pushUndo() {
        undoStack.append(items)
        if undoStack.count > maxUndoStack { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        redoStack.append(items)
        items = undoStack.removeLast()
        saveItems()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(items)
        items = redoStack.removeLast()
        saveItems()
    }

    // MARK: - CRUD

    func addItem() {
        pushUndo()
        let newItem = TodoItem(title: "")
        var copy = items
        copy.append(newItem)
        items = copy
        saveItems()
    }

    func addSubtask(to parentId: UUID) {
        pushUndo()
        guard let idx = items.firstIndex(where: { $0.id == parentId }),
              !items[idx].isSubtask else { return }
        let subtask = TodoItem(title: "", isCompleted: false, isSubtask: true)
        var copy = items
        copy[idx].subtasks.append(subtask)
        items = copy
        saveItems()
    }

    func deleteItem(_ id: UUID) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks.remove(at: ci)
        } else if let ci = childIdx {
            copy.remove(at: ci)
        }
        items = copy
        saveItems()
    }

    func setItemStyle(id: UUID, color: String?, bold: Bool, italic: Bool, fontSize: Double?) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].textColor = color
            copy[pi].subtasks[ci].isBold = bold
            copy[pi].subtasks[ci].isItalic = italic
            copy[pi].subtasks[ci].fontSize = fontSize
        } else if let ci = childIdx {
            copy[ci].textColor = color
            copy[ci].isBold = bold
            copy[ci].isItalic = italic
            copy[ci].fontSize = fontSize
        }
        items = copy
        saveItems()
    }

    func setDueDate(id: UUID, date: Date?) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].dueDate = date
        } else if let ci = childIdx {
            copy[ci].dueDate = date
        }
        items = copy
        saveItems()
    }

    func setDueDateTime(id: UUID, date: Date, isAllDay: Bool) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].dueDate = date
            copy[pi].subtasks[ci].isAllDay = isAllDay
        } else if let ci = childIdx {
            copy[ci].dueDate = date
            copy[ci].isAllDay = isAllDay
        }
        items = copy
        saveItems()
    }

    func toggleCompleted(_ id: UUID) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].isCompleted.toggle()
            copy[pi].isCompleted = copy[pi].subtasks.allSatisfy(\.isCompleted)
        } else if let ci = childIdx {
            copy[ci].isCompleted.toggle()
        }
        items = copy
        saveItems()
    }

    func updateTitle(_ id: UUID, title: String) {
        pushUndo()
        let (parentIdx, childIdx) = findItemIndex(id)
        var copy = items
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].title = title
        } else if let ci = childIdx {
            copy[ci].title = title
        }
        items = copy
        saveItems()
    }

    func appendToTitle(id: UUID, text: String) {
        pushUndo()
        var copy = items
        let (parentIdx, childIdx) = findItemIndex(id)
        if let pi = parentIdx, let ci = childIdx {
            copy[pi].subtasks[ci].title += text
        } else if let ci = childIdx {
            copy[ci].title += text
        }
        items = copy
        saveItems()
    }

    // MARK: - 钉到屏幕

    var isPinnedBreathingEnabled = false {
        didSet { UserDefaults.standard.set(isPinnedBreathingEnabled, forKey: "pinnedBreathingEnabled") }
    }

    var onPinChanged: ((UUID, Bool) -> Void)?

    func pinItem(_ id: UUID) {
        pinnedItemIds.insert(id)
    }

    func unpinItem(_ id: UUID) {
        pinnedItemIds.remove(id)
    }

    // MARK: - 快捷键

    // MARK: - 开机自启

    var isLaunchAtLoginEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }

    // MARK: - 导出

    func exportJSON(to url: URL) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Export JSON error: \(error)")
        }
    }

    // MARK: - 批量操作

    var isSelectionMode = false
    var selectedIds: Set<UUID> = []

    func toggleSelection(_ id: UUID) {
        if selectedIds.contains(id) { selectedIds.remove(id) }
        else { selectedIds.insert(id) }
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedIds.removeAll()
    }

    func batchDelete() {
        pushUndo()
        var copy = items
        copy.removeAll { selectedIds.contains($0.id) || $0.subtasks.contains(where: { selectedIds.contains($0.id) }) }
        items = copy
        selectedIds.removeAll()
        isSelectionMode = false
        saveItems()
    }

    func batchToggleCompleted() {
        pushUndo()
        var copy = items
        for i in copy.indices {
            if selectedIds.contains(copy[i].id) {
                copy[i].isCompleted.toggle()
                for j in copy[i].subtasks.indices {
                    copy[i].subtasks[j].isCompleted.toggle()
                }
            } else {
                for j in copy[i].subtasks.indices {
                    if selectedIds.contains(copy[i].subtasks[j].id) {
                        copy[i].subtasks[j].isCompleted.toggle()
                    }
                }
            }
        }
        items = copy
        selectedIds.removeAll()
        isSelectionMode = false
        saveItems()
    }

    // MARK: - 自动备份

    var backupDirectory: URL? {
        get {
            if let path = UserDefaults.standard.string(forKey: "backupDirectory") {
                return URL(fileURLWithPath: path)
            }
            return nil
        }
        set { UserDefaults.standard.set(newValue?.path, forKey: "backupDirectory") }
    }

    var isAutoBackupEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isAutoBackupEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isAutoBackupEnabled") }
    }

    var backupIntervalMinutes: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "backupIntervalMinutes")
            return v > 0 ? v : 5
        }
        set { UserDefaults.standard.set(max(1, newValue), forKey: "backupIntervalMinutes") }
    }

    var backupMaxAgeDays: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "backupMaxAgeDays")
            return v > 0 ? v : 30
        }
        set { UserDefaults.standard.set(max(1, newValue), forKey: "backupMaxAgeDays") }
    }

    private var lastBackupDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastBackupDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastBackupDate") }
    }

    func saveBackup() {
        guard isAutoBackupEnabled, let dir = backupDirectory else { return }
        if let last = lastBackupDate,
           Date().timeIntervalSince(last) < Double(backupIntervalMinutes * 60) {
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "DueDay_\(formatter.string(from: Date())).json"
        let url = dir.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: url, options: .atomic)
            lastBackupDate = Date()
            cleanOldBackups(in: dir)
        } catch {
            print("Backup error: \(error)")
        }
    }

    private func cleanOldBackups(in dir: URL) {
        let cutoff = Date().addingTimeInterval(-Double(backupMaxAgeDays * 86400))
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey]) else { return }
        for file in files where file.lastPathComponent.hasPrefix("DueDay_") && file.pathExtension == "json" {
            if let attrs = try? file.resourceValues(forKeys: [.creationDateKey]),
               let created = attrs.creationDate, created < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    func listBackupFiles() -> [(url: URL, date: Date)] {
        guard let dir = backupDirectory else { return [] }
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey]) else { return [] }
        return files
            .filter { $0.lastPathComponent.hasPrefix("DueDay_") && $0.pathExtension == "json" }
            .compactMap { url in
                guard let attrs = try? url.resourceValues(forKeys: [.creationDateKey]),
                      let date = attrs.creationDate else { return nil }
                return (url, date)
            }
            .sorted { $0.date > $1.date }
    }

    // MARK: - 导入/恢复

    func restoreFromJSON(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else { return false }
        pushUndo()
        items = decoded
        saveItems()
        return true
    }

    // MARK: - Persistence

    private func saveItems() {
        sortStamp += 1
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: saveFile, options: .atomic)
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.saveBackup()
            }
        } catch {
            print("Save error: \(error)")
        }
    }

    private func loadItems() {
        guard let data = try? Data(contentsOf: saveFile),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return
        }
        items = decoded
    }
}
