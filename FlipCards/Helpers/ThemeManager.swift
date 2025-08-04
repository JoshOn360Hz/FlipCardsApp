import SwiftUI
import Combine

enum CardTheme: String, CaseIterable {
    case classic = "classic"
    case minimal = "minimal"
    case vibrant = "vibrant"
    case academic = "academic"
    case neon = "neon"
    case nature = "nature"
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        case .academic: return "Academic"
        case .neon: return "Neon"
        case .nature: return "Nature"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "square.stack"
        case .minimal: return "rectangle"
        case .vibrant: return "paintbrush.fill"
        case .academic: return "graduationcap.fill"
        case .neon: return "bolt.fill"
        case .nature: return "leaf.fill"
        }
    }
    
    var questionColors: [Color] {
        switch self {
        case .classic:
            return [.blue, .purple]
        case .minimal:
            return [Color(.systemGray3), Color(.systemGray4)]
        case .vibrant:
            return [.pink, .orange]
        case .academic:
            return [.indigo, .blue]
        case .neon:
            return [.cyan, .mint]
        case .nature:
            return [.green, .teal]
        }
    }
    
    var answerColors: [Color] {
        switch self {
        case .classic:
            return [.green, .teal]
        case .minimal:
            return [Color(.systemGray2), Color(.systemGray3)]
        case .vibrant:
            return [.purple, .pink]
        case .academic:
            return [.brown, .orange]
        case .neon:
            return [.purple, .blue]
        case .nature:
            return [.brown, .yellow]
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .classic:
            return Color(.systemBackground)
        case .minimal:
            return Color(.systemGray6)
        case .vibrant:
            return Color(.systemBackground)
        case .academic:
            return Color(.secondarySystemBackground)
        case .neon:
            return Color(.systemBackground)
        case .nature:
            return Color(.systemBackground)
        }
    }
    
    var darkModeBackgroundColor: Color {
        switch self {
        case .classic:
            return Color(.systemBackground)
        case .minimal:
            return Color(.systemGray5)
        case .vibrant:
            return Color(.systemBackground)
        case .academic:
            return Color(.secondarySystemBackground)
        case .neon:
            return Color(.black).opacity(0.8)
        case .nature:
            return Color(.systemBackground)
        }
    }
    
    func adaptiveBackgroundColor(for colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return darkModeBackgroundColor
        }
        return backgroundColor
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .classic, .academic:
            return 20
        case .minimal:
            return 8
        case .vibrant, .nature:
            return 24
        case .neon:
            return 16
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .classic, .academic:
            return 12
        case .minimal:
            return 4
        case .vibrant, .nature:
            return 16
        case .neon:
            return 20
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .classic, .vibrant, .nature:
            return 2
        case .minimal:
            return 1
        case .academic:
            return 3
        case .neon:
            return 2
        }
    }
    
    var primaryButtonColors: [Color] {
        switch self {
        case .classic:
            return [.blue, .purple]
        case .minimal:
            return [Color(.systemGray3), Color(.systemGray4)]
        case .vibrant:
            return [.pink, .orange]
        case .academic:
            return [.indigo, .blue]
        case .neon:
            return [.cyan, .mint]
        case .nature:
            return [.green, .teal]
        }
    }
    
    var correctButtonColors: [Color] {
        switch self {
        case .classic:
            return [.green, .teal]
        case .minimal:
            return [Color(.systemGray2), Color(.systemGray3)]
        case .vibrant:
            return [.green, .mint]
        case .academic:
            return [.green, .teal]
        case .neon:
            return [.green, .cyan]
        case .nature:
            return [.green, .mint]
        }
    }
    
    var incorrectButtonColors: [Color] {
        switch self {
        case .classic:
            return [.red, .pink]
        case .minimal:
            return [Color(.systemGray), Color(.systemGray2)]
        case .vibrant:
            return [.red, .orange]
        case .academic:
            return [.red, .orange]
        case .neon:
            return [.red, .purple]
        case .nature:
            return [.red, .yellow]
        }
    }
    
    var accentGlowColor: Color {
        switch self {
        case .classic:
            return .blue
        case .minimal:
            return Color(.systemGray4)
        case .vibrant:
            return .pink
        case .academic:
            return .indigo
        case .neon:
            return .cyan
        case .nature:
            return .green
        }
    }
    
    var secondaryAccentColor: Color {
        switch self {
        case .classic:
            return .purple
        case .minimal:
            return Color(.systemGray3)
        case .vibrant:
            return .orange
        case .academic:
            return .blue
        case .neon:
            return .mint
        case .nature:
            return .teal
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @Published var accentColor: Color = .blue
    @Published var colorScheme: ColorScheme? = nil
    @Published var cardTheme: CardTheme = .classic
    
    private let accentColorKey = "accentColor"
    private let colorSchemeKey = "colorScheme"
    private let cardThemeKey = "cardTheme"
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        let savedAccentColor = UserDefaults.standard.string(forKey: accentColorKey) ?? "blue"
        accentColor = colorFromString(savedAccentColor)
        
        let savedColorScheme = UserDefaults.standard.string(forKey: colorSchemeKey) ?? "system"
        colorScheme = colorSchemeFromString(savedColorScheme)
        
        let savedCardTheme = UserDefaults.standard.string(forKey: cardThemeKey) ?? "classic"
        cardTheme = CardTheme(rawValue: savedCardTheme) ?? .classic
        
        SettingsHelper.applyColorScheme(savedColorScheme)
    }
    
    func updateAccentColor(_ colorName: String) {
        accentColor = colorFromString(colorName)
        UserDefaults.standard.set(colorName, forKey: accentColorKey)
    }
    
    func updateColorScheme(_ schemeName: String) {
        colorScheme = colorSchemeFromString(schemeName)
        UserDefaults.standard.set(schemeName, forKey: colorSchemeKey)
        SettingsHelper.applyColorScheme(schemeName)
    }
    
    func updateCardTheme(_ theme: CardTheme) {
        cardTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: cardThemeKey)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .blue
        }
    }
    
    private func colorSchemeFromString(_ schemeName: String) -> ColorScheme? {
        switch schemeName {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
}

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

extension View {
    func themedAccentColor() -> some View {
        self.modifier(ThemedAccentColorModifier())
    }
    
    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }
    
    func themedForeground() -> some View {
        self.modifier(ThemedForegroundModifier())
    }
}

struct ThemedAccentColorModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content.foregroundColor(themeManager.accentColor)
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content.background(themeManager.accentColor)
    }
}

struct ThemedForegroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content.foregroundColor(themeManager.accentColor)
    }
}
