<p align="center">
  <img src="assets/icon.png" width="128" alt="Do Now">
</p>

# DueDay

macOS 菜单栏倒数日 app。

基于 [Do Now](https://github.com/your-username/do-now) 重构。保留核心的待办事项和钉住提醒功能，删除了多余功能，优化了功能，美化了界面UI和交互。

## 功能

- 待办事项管理：创建、编辑、删除、完成勾选
- 子任务支持（最多一层）
- 截止日期/时间设置（全天事件 / 精确到分钟）
- 倒数日显示：卡片 hover 展开、悬浮窗常驻
- 钉到屏幕：浮动窗口，自动恢复，强调显示倒数日期时间
- 文字样式：49 色 / 粗体 / 斜体 / 字号
- 300+ emoji 表情插入
- 主题切换：系统默认 / 深邃黑色
- 导入/导出 JSON
- 自动备份
- 批量选择、撤销/重做

## Requirements

- macOS 14.0 or later
- Apple Silicon or Intel (build with `ARCHS="arm64 x86_64"` for Intel support)

## 构建

```bash
bash build.sh
```

一键生成 Xcode 项目、编译、打包 DMG。

## 项目结构

```
DueDay/
├── Sources/
│   ├── DueDayApp.swift        # @main 入口 + AppDelegate
│   ├── Models/TodoItem.swift   # 数据模型
│   ├── ViewModels/             # @Observable 视图模型
│   ├── Theme/                  # 主题配置
│   ├── Views/                  # SwiftUI 视图
│   └── Helpers/                # 辅助函数
├── Resources/DueDay.icns      # 应用图标
├── project.yml                # XcodeGen 配置
└── build.sh                   # 一键编译脚本
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘N | 新建待办 |
| ⌘Z | 撤销 |
| ⇧⌘Z | 重做 |
| ⌘W | 关闭弹窗 |
| ⌘, | 设置 |
| ⌘/ | 帮助 |

## License

MIT

## Support

If you find Do Now helpful, consider supporting its development:


- **感谢赞助** — 如果Do Now对你有帮助，欢迎扫码赞助一杯咖啡 ☕

- <p align="center">
  <img src="assets/wechat-pay.png" width="128" >
  <img src="assets/Alipay.png" width="120" >
</p>


Your support helps cover developer costs and motivates continued improvement. Thank you! 🙌

