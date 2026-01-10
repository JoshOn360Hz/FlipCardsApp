import SwiftUI
import SwiftData

struct DeckGridView: View {
    let decks: [Deck]
    @Environment(\.modelContext) private var modelContext
    @State private var showingRenameAlert = false
    @State private var deckToRename: Deck?
    @State private var newDeckName = ""
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160), spacing: 16)
            ], spacing: 16) {
                ForEach(decks, id: \.id) { deck in
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        DeckCardView(deck: deck)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            deckToRename = deck
                            newDeckName = deck.name
                            showingRenameAlert = true
                        } label: {
                            Label("Rename Deck", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteDeck(deck)
                        } label: {
                            Label("Delete Deck", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Rename Deck", isPresented: $showingRenameAlert) {
            TextField("Deck name", text: $newDeckName)
                .textInputAutocapitalization(.words)
            
            Button("Cancel", role: .cancel) {
                deckToRename = nil
                newDeckName = ""
            }
            
            Button("Rename") {
                renameDeck()
            }
            .disabled(newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for the deck.")
        }
    }
    
    private func deleteDeck(_ deck: Deck) {
        modelContext.delete(deck)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting deck: \(error)")
        }
    }
    
    private func renameDeck() {
        guard let deck = deckToRename else { return }
        
        let trimmedName = newDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        deck.name = trimmedName
        
        do {
            try modelContext.save()
        } catch {
            print("Error renaming deck: \(error)")
        }
        
        // Reset state
        deckToRename = nil
        newDeckName = ""
    }
}
