import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @Published var accentColor: Color = .blue
    @Published var colorScheme: ColorScheme? = nil
    
    private let accentColorKey = "accentColor"
    private let colorSchemeKey = "colorScheme"
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        let savedAccentColor = UserDefaults.standard.string(forKey: accentColorKey) ?? "blue"
        accentColor = colorFromString(savedAccentColor)
        
        let savedColorScheme = UserDefaults.standard.string(forKey: colorSchemeKey) ?? "system"
        colorScheme = colorSchemeFromString(savedColorScheme)
        
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
