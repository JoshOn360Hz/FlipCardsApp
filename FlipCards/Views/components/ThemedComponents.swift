import SwiftUI


struct ThemedButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    @EnvironmentObject var themeManager: ThemeManager
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
                .cornerRadius(12)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return themeManager.accentColor
        case .outline:
            return themeManager.accentColor
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeManager.accentColor
        case .secondary:
            return themeManager.accentColor.opacity(0.1)
        case .outline:
            return .clear
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return .clear
        case .outline:
            return themeManager.accentColor
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .primary, .secondary:
            return 0
        case .outline:
            return 2
        }
    }
}

struct ThemedProgressView: View {
    let value: Double
    let label: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: themeManager.accentColor))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

struct ThemedBadge: View {
    let text: String
    let style: BadgeStyle
    @EnvironmentObject var themeManager: ThemeManager
    
    enum BadgeStyle {
        case filled
        case outline
        case subtle
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .overlay(
                Capsule()
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .clipShape(Capsule())
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outline:
            return themeManager.accentColor
        case .subtle:
            return themeManager.accentColor
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return themeManager.accentColor
        case .outline:
            return .clear
        case .subtle:
            return themeManager.accentColor.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .filled, .subtle:
            return .clear
        case .outline:
            return themeManager.accentColor
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .filled, .subtle:
            return 0
        case .outline:
            return 1
        }
    }
}

struct ThemedToggle: View {
    let title: String
    @Binding var isOn: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))
    }
}

struct ThemedNavigationLink<Destination: View>: View {
    let title: String
    let subtitle: String?
    let destination: Destination
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, subtitle: String? = nil, icon: String, destination: Destination) {
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
        self.icon = icon
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

