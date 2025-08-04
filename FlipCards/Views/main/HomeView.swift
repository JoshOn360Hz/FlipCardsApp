import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]
    @State private var showingAddDeck = false
    @State private var showingSettings = false
    @State private var newDeckName = ""
    @State private var selectedGlyph: DeckGlyph = .books
    @State private var selectedBackground: DeckBackgroundColor = .blue
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
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
        }
    }
    
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
