import SwiftUI

class SettingsHelper {
    static func applyColorScheme(_ scheme: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch scheme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        case "system":
            window.overrideUserInterfaceStyle = .unspecified
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    static func iconForScheme(_ scheme: String) -> String {
        switch scheme {
        case "light":
            return "sun.max.fill"
        case "dark":
            return "moon.fill"
        case "system":
            return "circle.lefthalf.filled"
        default:
            return "circle.lefthalf.filled"
        }
    }
    
    static func titleForScheme(_ scheme: String) -> String {
        switch scheme {
        case "light":
            return "Light"
        case "dark":
            return "Dark"
        case "system":
            return "System"
        default:
            return "System"
        }
    }
}
