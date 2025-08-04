import SwiftUI
import SwiftData

@main
struct FlipCardsApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var themeManager = ThemeManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Deck.self,
            Card.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView(hasSeenOnboarding: $hasSeenOnboarding)
                .environment(\.themeManager, themeManager)
                .environmentObject(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct AppRootView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView(showOnboarding: $showOnboarding)
                    .onAppear {
                        showOnboarding = true
                    }
                    .onChange(of: showOnboarding) { _, newValue in
                        if !newValue {
                            hasSeenOnboarding = true
                        }
                    }
            }
        }
    }
}
