import SwiftUI
import SwiftData

struct DeckGridView: View {
    let decks: [Deck]
    @Environment(\.modelContext) private var modelContext
    
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
    }
    
    private func deleteDeck(_ deck: Deck) {
        modelContext.delete(deck)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting deck: \(error)")
        }
    }
}
