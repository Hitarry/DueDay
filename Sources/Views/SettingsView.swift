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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("主题风格")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        ForEach(ThemeType.allCases, id: \.self) { theme in
                            themeButton(theme: theme)
                        }
                    }

                    Divider().padding(.vertical, 12)

                    // General
                    VStack(alignment: .leading, spacing: 8) {
                        Text("通用")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Toggle(isOn: $launchAtLogin) {
                            HStack(spacing: 10) {
                                Image(systemName: "power")
                                    .font(.system(size: 16))
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("开机自启")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("登录 Mac 后自动启动")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(newValue)
                        }
                    }

                    Divider().padding(.vertical, 12)

                    // Export/Import
                    VStack(alignment: .leading, spacing: 8) {
                        Text("导入/导出数据")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            exportButton("导出", icon: "arrow.down.doc") { export(.json) }
                            exportButton("导入", icon: "arrow.up.doc") { importFile(.json) }
                        }
                    }

                    Divider().padding(.vertical, 12)

                    // Restore from backups
                    if let dir = viewModel.backupDirectory, FileManager.default.fileExists(atPath: dir.path) {
                        let backups = viewModel.listBackupFiles()
                        if !backups.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("从备份恢复")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)

                                ForEach(backups.prefix(10), id: \.url) { file in
                                    Button(action: { confirmRestore(url: file.url) }) {
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 11))
                                            Text(file.date, style: .date)
                                                .font(.system(size: 11))
                                            Text(file.date, style: .time)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("恢复")
                                                .font(.system(size: 10))
                                                .foregroundColor(.accentColor)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.primary.opacity(0.03))
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Divider().padding(.vertical, 12)

                    // Auto backup
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自动备份")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Toggle(isOn: $autoBackup) {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("启用自动备份")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("每次保存时自动备份到指定目录")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                        .onChange(of: autoBackup) { _, newValue in
                            viewModel.isAutoBackupEnabled = newValue
                        }

                        Button(action: chooseBackupDir) {
                            HStack(spacing: 10) {
                                Image(systemName: "folder")
                                    .font(.system(size: 16))
                                    .frame(width: 22)
                                Text(backupPath.isEmpty ? "选择备份目录" : backupPath)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundColor(backupPath.isEmpty ? .primary : .secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        if !backupPath.isEmpty {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("备份间隔")
                                        .font(.system(size: 11, weight: .medium))
                                    Stepper("\(backupInterval) 分钟",
                                            value: $backupInterval, in: 1...120)
                                        .font(.system(size: 11))
                                        .fixedSize()
                                        .onChange(of: backupInterval) { _, v in
                                            viewModel.backupIntervalMinutes = v
                                        }
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("保留天数")
                                        .font(.system(size: 11, weight: .medium))
                                    Stepper("\(backupMaxAge) 天",
                                            value: $backupMaxAge, in: 1...365)
                                        .font(.system(size: 11))
                                        .fixedSize()
                                        .onChange(of: backupMaxAge) { _, v in
                                            viewModel.backupMaxAgeDays = v
                                        }
                                }
                            }
                            .padding(.leading, 32)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                if viewModel.hasCompletedItems() {
                    Button(action: { viewModel.clearAllCompleted() }) {
                        Text("清除已完成")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text("DueDay v1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 320, height: 520)
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
            HStack(spacing: 12) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 18))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.system(size: 14, weight: .medium))
                    Text(theme.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
