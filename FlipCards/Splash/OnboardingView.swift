import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedAccentColor: String = "blue"
    @State private var selectedCardTheme: CardTheme = .classic
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to FlipCards",
            subtitle: "Your personal study companion",
            imageName: "logo",
            description: "Master any subject with interactive flashcards designed to boost your learning efficiency and retention.",
            showLogo: true
        ),
        OnboardingPage(
            title: "Create Custom Decks",
            subtitle: "Organize your study materials",
            imageName: "rectangle.stack.fill",
            description: "Create themed decks with custom icons and colors. Organize your flashcards by subject, topic, or difficulty level.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Add Cards",
            subtitle: "Questions and answers",
            imageName: "square.stack.3d.forward.dottedline.fill",
            description: "Create flashcards with questions on the front and detailed answers on the back. Set difficulty levels to optimize your learning.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Interactive Quiz Mode",
            subtitle: "Test your knowledge",
            imageName: "brain.head.profile",
            description: "Take interactive quizzes with our smart study system. Tap cards to reveal answers and mark your performance.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Difficulty System",
            subtitle: "Adaptive learning",
            imageName: "gearshape.2.fill",
            description: "Hard cards appear more frequently while easy cards appear less often, maximizing your study efficiency.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Track Your Progress",
            subtitle: "Monitor your improvement",
            imageName: "chart.line.uptrend.xyaxis",
            description: "View detailed statistics including accuracy rates, review counts, and study patterns for each card and deck.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Search & Organize",
            subtitle: "Find cards instantly",
            imageName: "magnifyingglass",
            description: "Quickly search through your cards and decks. Use the powerful search to find exactly what you need to study.",
            showLogo: false
        ),
        OnboardingPage(
            title: "Choose Your Style",
            subtitle: "Personalize your experience",
            imageName: "paintpalette.fill",
            description: "Select your favorite accent color to personalize FlipCards and make it truly yours.",
            showLogo: false,
            isColorPicker: true
        ),
        OnboardingPage(
            title: "Pick Your Quiz Theme",
            subtitle: "Customize your study cards",
            imageName: "square.stack.3d.up.fill",
            description: "Choose a card theme that matches your learning style.",
            showLogo: false,
            isCardThemePicker: true
        ),
        OnboardingPage(
            title: "Ready to Start Learning?",
            subtitle: "Begin your study journey",
            imageName: "graduationcap.fill",
            description: "You're all set! Create your first deck, add some cards, and start building your knowledge base today.",
            showLogo: false
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], selectedAccentColor: $selectedAccentColor, selectedCardTheme: $selectedCardTheme)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        if currentPage == 0 {
                            Button("Skip") {
                                showOnboarding = false
                            }
                            .font(.headline)
                            .foregroundColor(colorFromString(selectedAccentColor))
                            .animation(.easeInOut(duration: 0.2), value: selectedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                        } else {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .font(.headline)
                            .foregroundColor(colorFromString(selectedAccentColor))
                            .animation(.easeInOut(duration: 0.2), value: selectedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                        }
                        
                        Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                            if currentPage == pages.count - 1 {
                                showOnboarding = false
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var selectedAccentColor: String
    @Binding var selectedCardTheme: CardTheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                    
                    if page.showLogo {
                        Image(page.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        Image(systemName: page.imageName)
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                }
                
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text(page.subtitle)
                        .font(.title3)
                        .foregroundColor(colorFromString(selectedAccentColor))
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.2), value: selectedAccentColor)
                }
            }
            
            if page.isColorPicker {
                VStack(spacing: 20) {
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 32)
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ForEach(["blue", "red", "green", "orange"], id: \.self) { colorName in
                                Circle()
                                    .fill(colorFromString(colorName))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAccentColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .scaleEffect(selectedAccentColor == colorName ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedAccentColor)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedAccentColor = colorName
                                        }
                                        themeManager.updateAccentColor(colorName)
                                        
                                        print("Selected color: \(colorName)") 
                                        
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(["purple", "pink", "yellow", "cyan"], id: \.self) { colorName in
                                Circle()
                                    .fill(colorFromString(colorName))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAccentColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .scaleEffect(selectedAccentColor == colorName ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedAccentColor)
                                    .onTapGesture {
                                        selectedAccentColor = colorName
                                        themeManager.updateAccentColor(colorName)
                                        
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(["mint", "indigo"], id: \.self) { colorName in
                                Circle()
                                    .fill(colorFromString(colorName))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAccentColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .scaleEffect(selectedAccentColor == colorName ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedAccentColor)
                                    .onTapGesture {
                                        selectedAccentColor = colorName
                                        themeManager.updateAccentColor(colorName)
                                        
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
            } else if page.isCardThemePicker {
                VStack(spacing: 20) {
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 32)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                        ForEach(CardTheme.allCases, id: \.self) { theme in
                            CardThemePreviewCard(
                                theme: theme,
                                isSelected: selectedCardTheme == theme,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCardTheme = theme
                                    }
                                    themeManager.updateCardTheme(theme)
                                    
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
    let showLogo: Bool
    let isColorPicker: Bool
    let isCardThemePicker: Bool
    
    init(title: String, subtitle: String, imageName: String, description: String, showLogo: Bool, isColorPicker: Bool = false, isCardThemePicker: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.description = description
        self.showLogo = showLogo
        self.isColorPicker = isColorPicker
        self.isCardThemePicker = isCardThemePicker
    }
}

struct CardThemePreviewCard: View {
    let theme: CardTheme
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius * 0.6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: theme.questionColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 60)
                    .shadow(color: .black.opacity(0.1), radius: theme.shadowRadius * 0.3, x: 0, y: 2)
                
                Text("Aa")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: theme.icon)
                        .font(.caption)
                        .foregroundColor(theme.accentGlowColor)
                    
                    Text(theme.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveBackgroundColor(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? theme.accentGlowColor : Color.secondary.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}
