import SwiftUI

enum ThemeType: String, CaseIterable, Codable {
    case system = "系统默认"
    case dark = "深邃黑色"

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .system: return "纯白界面，经典 macOS 风格"
        case .dark: return "深色沉浸，减少视觉干扰"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct ThemeConfig {
    let name: ThemeType

    let canvasBackground: Color
    let cardBackground: Color
    let listBackground: Color
    let dividerColor: Color
    let borderColor: Color
    let primaryText: Color
    let secondaryText: Color
    let accentColor: Color

    var menuBarBackground: Color {
        switch name {
        case .system: return Color(nsColor: .windowBackgroundColor).opacity(0.65)
        case .dark: return .clear
        }
    }

    var cardFill: Color {
        switch name {
        case .system: return Color.primary.opacity(0.07)
        case .dark: return Color.white.opacity(0.13)
        }
    }

    var cardStroke: Color {
        switch name {
        case .system: return Color.primary.opacity(0.13)
        case .dark: return Color.white.opacity(0.20)
        }
    }

    static func config(for theme: ThemeType) -> ThemeConfig {
        switch theme {
        case .system:
            return ThemeConfig(
                name: .system,
                canvasBackground: Color(nsColor: .windowBackgroundColor),
                cardBackground: Color(nsColor: .controlBackgroundColor),
                listBackground: Color(nsColor: .controlBackgroundColor),
                dividerColor: .primary.opacity(0.1),
                borderColor: .primary.opacity(0.08),
                primaryText: .primary,
                secondaryText: .secondary,
                accentColor: Color(red: 0.85, green: 0.25, blue: 0.25)
            )
        case .dark:
            return ThemeConfig(
                name: .dark,
                canvasBackground: Color(red: 0.06, green: 0.06, blue: 0.08),
                cardBackground: Color(red: 0.10, green: 0.10, blue: 0.13),
                listBackground: Color(red: 0.08, green: 0.08, blue: 0.11),
                dividerColor: .white.opacity(0.08),
                borderColor: .white.opacity(0.06),
                primaryText: .white.opacity(0.92),
                secondaryText: .white.opacity(0.55),
                accentColor: Color(red: 0.90, green: 0.30, blue: 0.30)
            )
        }
    }
}
