import SwiftUI

struct ColorSchemePickerComponent: View {
    @Binding var colorScheme: String
    let currentAccentColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Scheme")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                
                GeometryReader { geometry in
                    let segmentWidth = geometry.size.width / CGFloat(3)
                    let selectedIndex = colorScheme == "light" ? 1 : (colorScheme == "dark" ? 2 : 0)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentAccentColor)
                        .frame(width: segmentWidth - 8) 
                        .padding(4)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: colorScheme)
                }
                
                HStack(spacing: 0) {
                    ForEach(["system", "light", "dark"], id: \.self) { scheme in
                        Button(action: {
                            colorScheme = scheme
                            themeManager.updateColorScheme(scheme)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: SettingsHelper.iconForScheme(scheme))
                                    .font(.system(size: 22))
                                    .foregroundColor(colorScheme == scheme ? .white : .secondary)
                                
                                Text(SettingsHelper.titleForScheme(scheme))
                                    .font(.caption)
                                    .fontWeight(colorScheme == scheme ? .semibold : .regular)
                                    .foregroundColor(colorScheme == scheme ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 80)
        }
    }
}

struct AppearanceSettingsComponent: View {
    @Binding var accentColor: String
    @Binding var colorScheme: String
    let currentAccentColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    private let accentColorOptions: [(name: String, color: Color)] = [
        ("blue", .blue), ("red", .red), ("orange", .orange), ("yellow", .yellow), ("green", .green),
        ("purple", .purple), ("pink", .pink), ("teal", .teal), ("indigo", .indigo), ("mint", .mint)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 18) {
                ForEach(accentColorOptions, id: \.name) { option in
                    Button {
                        accentColor = option.name
                        themeManager.updateAccentColor(option.name)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 44, height: 44)
                            
                            if accentColor == option.name {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(option.color)
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    Form {
        Section("Appearance") {
            AppearanceSettingsComponent(
                accentColor: .constant("blue"),
                colorScheme: .constant("system"),
                currentAccentColor: .blue
            )
            
            ColorSchemePickerComponent(
                colorScheme: .constant("system"),
                currentAccentColor: .blue
            )
        }
    }
}
