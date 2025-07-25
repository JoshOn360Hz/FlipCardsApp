import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let deck: Deck
    @State private var showingAddCard = false
    @State private var searchText = ""
    
    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return deck.cards.sorted { $0.frontText < $1.frontText }
        } else {
            return deck.cards.filter { card in
                card.frontText.localizedCaseInsensitiveContains(searchText) ||
                card.backText.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.frontText < $1.frontText }
        }
    }
    
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
            
            VStack {
                if deck.cards.isEmpty {
                    EmptyCardsView()
                } else {
                    CardListView(cards: filteredCards, deck: deck)
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search cards...")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !deck.cards.isEmpty {
                    NavigationLink(destination: QuizView(deck: deck)) {
                        Image(systemName: "play.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                
                Button(action: { showingAddCard = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            CardEditorView(deck: deck, card: nil, isPresented: $showingAddCard)
        }
    }
}

struct EmptyCardsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [themeManager.accentColor.opacity(0.1), themeManager.accentColor.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                
                VStack(spacing: 8) {
                    Text("No Cards Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Add your first card to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CardListView: View {
    let cards: [Card]
    let deck: Deck
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(cards, id: \.id) { card in
                NavigationLink(destination: CardDetailView(card: card)) {
                    CardRowView(card: card)
                }
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteCards)
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        for index in offsets {
            let card = cards[index]
            modelContext.delete(card)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting cards: \(error)")
        }
    }
}

struct CardRowView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: card.glyph.rawValue)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.frontText)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !card.backText.isEmpty {
                        Text(card.backText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if card.timesReviewed > 0 {
                        HStack(spacing: 16) {
                            Label("\(card.timesReviewed)", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label("\(Int(card.correctPercentage))%", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(card.correctPercentage >= 70 ? .green : card.correctPercentage >= 50 ? .orange : .red)
                        }
                    }
                }
                
                DifficultyBadge(difficulty: card.difficulty)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 1)
        )
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(difficultyColor)
                .frame(width: 8, height: 8)
            
            Text(difficulty.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(difficultyColor.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(difficultyColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct CardDetailView: View {
    let card: Card
    @State private var showingEditor = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Front")
                            .font(.headline)
                        Spacer()
                        DifficultyBadge(difficulty: card.difficulty)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.frontText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Back")
                        .font(.headline)
                    
                    Text(card.backText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                if card.timesReviewed > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            StatRow(label: "Times Reviewed", value: "\(card.timesReviewed)")
                            StatRow(label: "Times Correct", value: "\(card.timesCorrect)")
                            StatRow(label: "Accuracy", value: "\(Int(card.correctPercentage))%")
                            
                            if let lastReviewed = card.lastReviewed {
                                StatRow(label: "Last Reviewed", value: lastReviewed.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            CardEditorView(deck: card.deck, card: card, isPresented: $showingEditor)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}
