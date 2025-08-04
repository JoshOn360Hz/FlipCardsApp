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
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                
                Button(action: { showingAddCard = true }) {
                    Image(systemName: "plus")
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
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: card.glyph.rawValue)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    if !card.frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(card.frontText)
                            .font(.headline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if card.frontDrawingData != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.tip.crop.circle.fill")
                                .font(.headline)
                                .foregroundColor(themeManager.accentColor)
                            Text("Drawing")
                                .font(.headline)
                                .foregroundColor(themeManager.accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let frontDrawingData = card.frontDrawingData {
                        DrawingPreview(
                            drawingData: frontDrawingData,
                            size: CGSize(width: 200, height: 60),
                            showFullDrawing: true
                        )
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    if card.cardType == .multipleChoice {
                        let filledOptions = card.multipleChoiceOptions.enumerated().filter { !$0.element.isEmpty }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(filledOptions.enumerated()), id: \.offset) { optionIndex, option in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(option.offset == card.correctChoiceIndex ? themeManager.accentColor : Color.secondary.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(option.element)
                                        .font(.subheadline)
                                        .foregroundColor(option.offset == card.correctChoiceIndex ? themeManager.accentColor : .secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } else if !card.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(card.backText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if card.backDrawingData != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.tip.crop.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Drawing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
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
    @EnvironmentObject var themeManager: ThemeManager
    
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
                        VStack(alignment: .leading, spacing: 12) {
                            if !card.frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(card.frontText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let frontDrawingData = card.frontDrawingData {
                                DrawingPreview(
                                    drawingData: frontDrawingData,
                                    size: CGSize(width: 300, height: 150),
                                    showFullDrawing: true
                                )
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            if card.frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && card.frontDrawingData == nil {
                                Text("No content")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                if card.cardType == .multipleChoice {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Answer Options")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            let filledOptions = card.multipleChoiceOptions.enumerated().filter { !$0.element.isEmpty }
                            
                            ForEach(Array(filledOptions.enumerated()), id: \.offset) { optionIndex, option in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(option.offset == card.correctChoiceIndex ? themeManager.accentColor : Color.secondary.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(option.element)
                                        .font(.body)
                                        .foregroundColor(option.offset == card.correctChoiceIndex ? themeManager.accentColor : .primary)
                                        .fontWeight(option.offset == card.correctChoiceIndex ? .medium : .regular)
                                    
                                    Spacer()
                                    
                                    if option.offset == card.correctChoiceIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Back")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if !card.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(card.backText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let backDrawingData = card.backDrawingData {
                                DrawingPreview(
                                    drawingData: backDrawingData,
                                    size: CGSize(width: 300, height: 150),
                                    showFullDrawing: true
                                )
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            if card.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && card.backDrawingData == nil {
                                Text("No content")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
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
