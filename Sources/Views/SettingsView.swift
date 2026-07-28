import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(TodoViewModel.self) private var viewModel
    @State private var launchAtLogin = false
    @State private var autoBackup = false
    @State private var backupPath = ""
    @State private var backupInterval = 5
    @State private var backupMaxAge = 30
    @State private var showRestoreAlert = false
    @State private var restoreURL: URL?
    @State private var restoreError = false

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Theme
                    VStack(alignment: .leading, spacing: 4) {
                        Text("主题风格")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)

                        ForEach(ThemeType.allCases, id: \.self) { theme in
                            themeButton(theme: theme)
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // General
                    Toggle(isOn: $launchAtLogin) {
                        Text("开机自启").font(.system(size: 12))
                    }
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }

                    Divider().padding(.vertical, 8)

                    // Export/Import
                    HStack(spacing: 6) {
                        exportButton("导出", icon: "arrow.down.doc") { export(.json) }
                        exportButton("导入", icon: "arrow.up.doc") { importFile(.json) }
                    }

                    Divider().padding(.vertical, 8)

                    // Auto backup
                    Toggle(isOn: $autoBackup) {
                        Text("自动备份").font(.system(size: 12))
                    }
                    .toggleStyle(.switch)
                    .onChange(of: autoBackup) { _, newValue in
                        viewModel.isAutoBackupEnabled = newValue
                    }

                    Button(action: chooseBackupDir) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder").font(.system(size: 11))
                            Text(backupPath.isEmpty ? "选择备份目录" : backupPath)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(backupPath.isEmpty ? .primary : .secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    if !backupPath.isEmpty {
                        HStack(spacing: 12) {
                            Stepper("间隔 \(backupInterval)分", value: $backupInterval, in: 1...120)
                                .font(.system(size: 10)).fixedSize()
                                .onChange(of: backupInterval) { _, v in viewModel.backupIntervalMinutes = v }
                            Stepper("保留 \(backupMaxAge)天", value: $backupMaxAge, in: 1...365)
                                .font(.system(size: 10)).fixedSize()
                                .onChange(of: backupMaxAge) { _, v in viewModel.backupMaxAgeDays = v }
                        }
                        .padding(.top, 4)
                    }

                    // Restore from backups
                    let backups = viewModel.listBackupFiles()
                    if !backups.isEmpty {
                        Divider().padding(.vertical, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("从备份恢复").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                            ForEach(backups.prefix(5), id: \.url) { file in
                                Button(action: { confirmRestore(url: file.url) }) {
                                    HStack(spacing: 4) {
                                        Text(file.date, style: .date).font(.system(size: 10))
                                        Text(file.date, style: .time).font(.system(size: 10)).foregroundColor(.secondary)
                                        Spacer()
                                        Text("恢复").font(.system(size: 9)).foregroundColor(.accentColor)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.primary.opacity(0.03)).cornerRadius(3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Divider()

            HStack {
                if viewModel.hasCompletedItems() {
                    Button(action: { viewModel.clearAllCompleted() }) {
                        Text("清除已完成").font(.system(size: 10)).foregroundColor(.red.opacity(0.6))
                    }.buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding(12)
        .frame(width: 240, height: 320)
        .alert("恢复数据", isPresented: $showRestoreAlert) {
            Button("恢复", role: .destructive) { performRestore() }
            Button("取消", role: .cancel) { }
        } message: {
            Text(restoreError ? "文件格式错误，无法恢复" : "这将替换当前所有数据，确定要恢复吗？")
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            autoBackup = viewModel.isAutoBackupEnabled
            backupPath = viewModel.backupDirectory?.path ?? ""
            backupInterval = viewModel.backupIntervalMinutes
            backupMaxAge = viewModel.backupMaxAgeDays
        }
    }

    // MARK: - Actions

    private func exportButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }

    private func toggleLaunchAtLogin(_ enable: Bool) {
        viewModel.isLaunchAtLoginEnabled = enable
        do {
            if enable { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            print("Login item error: \(error)")
        }
    }

    private func chooseBackupDir() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "选择自动备份目录"
        panel.prompt = "选择"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.backupDirectory = url
        backupPath = url.path
    }

    private func export(_ format: ExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "DueDay_export.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.exportJSON(to: url)
    }

    private func importFile(_ format: ExportFormat) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let success = viewModel.restoreFromJSON(url: url)

        if !success {
            restoreError = true
            showRestoreAlert = true
        }
    }

    private func confirmRestore(url: URL) {
        restoreURL = url
        restoreError = false
        showRestoreAlert = true
    }

    private func performRestore() {
        guard let url = restoreURL else { return }
        let success = viewModel.restoreFromJSON(url: url)
        if !success {
            restoreError = true
            showRestoreAlert = true
        }
        restoreURL = nil
    }

    @ViewBuilder
    private func themeButton(theme: ThemeType) -> some View {
        let isSelected = viewModel.theme == theme
        Button(action: { viewModel.setTheme(theme) }) {
            HStack(spacing: 8) {
                Image(systemName: theme.iconName).font(.system(size: 14)).frame(width: 20)
                Text(theme.displayName).font(.system(size: 12))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor).font(.system(size: 13))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
