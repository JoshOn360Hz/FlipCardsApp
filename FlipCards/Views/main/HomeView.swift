import SwiftUI
import SwiftData
import AppIntents

// Typed navigation destinations used by both HomeView and DeckGridView
enum AppRoute: Hashable {
    case deck(UUID)
    case quiz(UUID)
    case card(cardID: UUID, deckID: UUID)
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]
    @State private var navigationPath = NavigationPath()
    @State private var showingAddDeck = false
    @State private var showingSettings = false
    @State private var newDeckName = ""
    @State private var selectedGlyph: DeckGlyph = .books
    @State private var selectedBackground: DeckBackgroundColor = .blue
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    if decks.isEmpty {
                        EmptyStateView()
                    } else {
                        DeckGridView(decks: decks)
                    }
                }
            }
            .navigationTitle("FlipCards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDeck = true }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingAddDeck) {
                AddDeckSheet(
                    isPresented: $showingAddDeck,
                    deckName: $newDeckName,
                    onSave: addDeck,
                    selectedGlyph: $selectedGlyph,
                    selectedBackground: $selectedBackground
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .deck(let id):
                    if let deck = decks.first(where: { $0.id == id }) {
                        DeckDetailView(deck: deck)
                    }
                case .quiz(let id):
                    if let deck = decks.first(where: { $0.id == id }) {
                        QuizView(deck: deck)
                    }
                case .card(let cardID, let deckID):
                    if let deck = decks.first(where: { $0.id == deckID }),
                       let card = deck.cards.first(where: { $0.id == cardID }) {
                        CardDetailView(card: card)
                    }
                }
            }
        }
        .onAppear {
            handlePendingNavigation()
        }
        .onChange(of: decks.count) {
            FlipCardsShortcuts.updateAppShortcutParameters()
            Task { await donateToSpotlight(decks: decks) }
        }
        .task {
            await donateToSpotlight(decks: decks)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDeck)) { notification in
            guard let deckId = notification.object as? UUID else { return }
            navigate(to: .deck(deckId))
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToQuiz)) { notification in
            guard let deckId = notification.object as? UUID else { return }
            navigate(to: .quiz(deckId))
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCard)) { notification in
            guard let info = notification.object as? [String: UUID],
                  let cardId = info["cardId"],
                  let deckId = info["deckId"] else { return }
            navigate(to: .card(cardID: cardId, deckID: deckId))
        }
    }

    // MARK: - Navigation

    private func navigate(to route: AppRoute) {
        navigationPath = NavigationPath()
        switch route {
        case .deck(let id):
            navigationPath.append(AppRoute.deck(id))
        case .quiz(let id):
            navigationPath.append(AppRoute.deck(id))
            navigationPath.append(AppRoute.quiz(id))
        case .card(let cardID, let deckID):
            navigationPath.append(AppRoute.deck(deckID))
            navigationPath.append(AppRoute.card(cardID: cardID, deckID: deckID))
        }
    }

    // Reads any navigation destination written by an App Intent before the app launched
    private func handlePendingNavigation() {
        guard let pending = UserDefaults.standard.dictionary(forKey: "FlipCards.pendingNavigation"),
              let type = pending["type"] as? String else { return }
        UserDefaults.standard.removeObject(forKey: "FlipCards.pendingNavigation")

        switch type {
        case "deck":
            if let idString = pending["id"] as? String, let id = UUID(uuidString: idString) {
                navigate(to: .deck(id))
            }
        case "quiz":
            if let idString = pending["id"] as? String, let id = UUID(uuidString: idString) {
                navigate(to: .quiz(id))
            }
        case "card":
            if let cardIdString = pending["cardId"] as? String,
               let deckIdString = pending["deckId"] as? String,
               let cardId = UUID(uuidString: cardIdString),
               let deckId = UUID(uuidString: deckIdString) {
                navigate(to: .card(cardID: cardId, deckID: deckId))
            }
        default:
            break
        }
    }

    // MARK: - Actions

    private func addDeck() {
        guard !newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let deck = Deck(
            name: newDeckName.trimmingCharacters(in: .whitespacesAndNewlines),
            glyph: selectedGlyph.rawValue,
            backgroundColor: selectedBackground.rawValue
        )
        modelContext.insert(deck)

        do {
            try modelContext.save()
            newDeckName = ""
            selectedGlyph = .books
            selectedBackground = .blue
            showingAddDeck = false
        } catch {
            print("Error saving deck: \(error)")
        }
    }
}
