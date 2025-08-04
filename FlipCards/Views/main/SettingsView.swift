import SwiftUI

private var isRunningOnMac: Bool {
    #if targetEnvironment(macCatalyst)
    return true
    #else
    if #available(iOS 14.0, *) {
        return ProcessInfo.processInfo.isiOSAppOnMac
    }
    return false
    #endif
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var showOnboarding = false
    @State private var showingIconSelector = false
    @State private var currentIconName: String = UIApplication.shared.alternateIconName ?? "Default"
    @EnvironmentObject var themeManager: ThemeManager
    @State private var accentColor: String = "blue"
    @State private var colorScheme: String = "system"
    
    private var currentAccentColor: Color {
        themeManager.accentColor
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    AppearanceSettingsComponent(
                        accentColor: $accentColor,
                        colorScheme: $colorScheme,
                        currentAccentColor: currentAccentColor
                    )
                    
                    ColorSchemePickerComponent(
                        colorScheme: $colorScheme,
                        currentAccentColor: currentAccentColor
                    )
                    
                    CardThemePickerComponent(
                        currentAccentColor: currentAccentColor
                    )
                    
                    if !isRunningOnMac {
                        Button(action: { showingIconSelector = true }) {
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(currentAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("App Icon")
                                        .foregroundColor(.primary)
                                    Text(displayNameForIcon(currentIconName))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Button(action: { showOnboarding = true }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(currentAccentColor)
                                .frame(width: 24, height: 24)
                            
                            Text("View Onboarding")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: { openSupportEmail() }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(currentAccentColor)
                                .frame(width: 24, height: 24)
                            
                            Text("Get Help")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Help")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(currentAccentColor)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FlipCards")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: { openWebsite() }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(currentAccentColor)
                                .frame(width: 24, height: 24)
                            
                            Text("FlipCards Website")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            accentColor = UserDefaults.standard.string(forKey: "accentColor") ?? "blue"
            colorScheme = UserDefaults.standard.string(forKey: "colorScheme") ?? "system"
            SettingsHelper.applyColorScheme(colorScheme)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
        }
        .sheet(isPresented: $showingIconSelector) {
            AppIconSelectorView(
                isPresented: $showingIconSelector,
                currentIconName: $currentIconName
            )
        }
    }
    
    private func displayNameForIcon(_ iconName: String) -> String {
        switch iconName {
        case "icon-dark-blue": return "Dark Blue"
        case "icon-dark-orange": return "Dark Orange"
        case "icon-dark-pink": return "Dark Pink"
        case "icon-dark-red": return "Dark Red"
        case "icon-dark-green": return "Dark Green"
        case "icon-light-blue": return "Light Blue"
        case "icon-light-orange": return "Light Orange"
        case "icon-light-pink": return "Light Pink"
        case "icon-light-green": return "Light Green"
        default: return "Default"
        }
    }
    
    private func openSupportEmail() {
        let email = "feedback@appsbyjosh.com"
        let subject = "FlipCards Support Request"
        let body = "Hi,\n\nI need help with FlipCards.\n\n"
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://getflipcards.app") {
            UIApplication.shared.open(url)
        }
    }
}

struct AppIconSelectorView: View {
    @Binding var isPresented: Bool
    @Binding var currentIconName: String
    @EnvironmentObject var themeManager: ThemeManager
    
    private let availableIcons: [(name: String, displayName: String)] = [
        ("Default", "Default"),
        ("icon-dark-blue", "Dark Blue"),
        ("icon-dark-orange", "Dark Orange"),
        ("icon-dark-pink", "Dark Pink"),
        ("icon-dark-red", "Dark Red"),
        ("icon-dark-green", "Dark Green"),
        ("icon-light-blue", "Light Blue"),
        ("icon-light-orange", "Light Orange"),
        ("icon-light-pink", "Light Pink"),
        ("icon-light-green", "Light Green")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableIcons, id: \.name) { icon in
                    Button(action: {
                        changeAppIcon(to: icon.name)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 50, height: 50)
                                
                                if icon.name == "Default" {
                                    Image("logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                } else {
                                    let previewImageName = "\(icon.name)-preview"
                                    if let image = UIImage(named: previewImageName) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(iconFallbackColor(for: icon.name))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                VStack(spacing: 2) {
                                                    Image(systemName: "app.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.white)
                                                    Text(String(icon.name.suffix(1)))
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            )
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(currentIconName == icon.name ? themeManager.accentColor : Color.clear, lineWidth: 2)
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(icon.displayName)
                                    .foregroundColor(.primary)
                                    .font(.headline)
                                
                                if icon.name == "Default" {
                                    Text("Original app icon")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(iconDescription(for: icon.name))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if currentIconName == icon.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.accentColor)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Choose App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func changeAppIcon(to iconName: String) {
        let newIconName = iconName == "Default" ? nil : iconName
        
        if UIApplication.shared.alternateIconName == newIconName {
            return
        }
        
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        
        UIApplication.shared.setAlternateIconName(newIconName) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.currentIconName = iconName
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    private func iconDescription(for iconName: String) -> String {
        return "Alternate icon"
    }
    
    private func iconFallbackColor(for iconName: String) -> Color {
        switch iconName {
        case let name where name.contains("blue"):
            return .blue
        case let name where name.contains("orange"):
            return .orange
        case let name where name.contains("pink"):
            return .pink
        case let name where name.contains("red"):
            return .red
        case let name where name.contains("green"):
            return .green
        default:
            return .gray
        }
    }
}

struct CardThemePickerComponent: View {
    let currentAccentColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSheet = false
    
    var body: some View {
        Button(action: { showingThemeSheet = true }) {
            HStack {
                Image(systemName: themeManager.cardTheme.icon)
                    .foregroundColor(currentAccentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiz Theme")
                        .foregroundColor(.primary)
                    Text(themeManager.cardTheme.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .sheet(isPresented: $showingThemeSheet) {
            CardThemeSelectionView(isPresented: $showingThemeSheet)
        }
    }
}

struct CardThemeSelectionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(CardTheme.allCases, id: \.rawValue) { theme in
                        CardThemePreview(
                            theme: theme,
                            isSelected: themeManager.cardTheme == theme,
                            onSelect: {
                                themeManager.updateCardTheme(theme)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Quiz Themes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct CardThemePreview: View {
    let theme: CardTheme
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: theme.icon)
                            .font(.caption)
                            .foregroundColor(theme.questionColors[0])
                        
                        Spacer()
                        
                        Circle()
                            .fill(theme.questionColors[0])
                            .frame(width: 6, height: 6)
                    }
                    
                    Text("Sample Question")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius * 0.6)
                        .fill(theme.backgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: theme.shadowRadius * 0.3, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius * 0.6)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.questionColors[0].opacity(0.3),
                                    theme.questionColors[1].opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: theme.borderWidth * 0.5
                        )
                )
                
                VStack(spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(theme.questionColors[index])
                                .frame(width: 8, height: 8)
                        }
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(theme.answerColors[index])
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
