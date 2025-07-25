import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let deck: Deck?
    let card: Card?
    @Binding var isPresented: Bool
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var selectedGlyph: DeckGlyph = .lightbulb
    
    private var isEditing: Bool {
        card != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Front (Question)")
                            .font(.headline)
                        
                        TextEditor(text: $frontText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Back (Answer)")
                            .font(.headline)
                        
                        TextEditor(text: $backText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    GlyphSelector(selectedGlyph: $selectedGlyph)
                    
                    DifficultySelector(selectedDifficulty: $selectedDifficulty)
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                    }
                    .foregroundColor(themeManager.accentColor)
                    .disabled(frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        if let card = card {
            frontText = card.frontText
            backText = card.backText
            selectedDifficulty = card.difficulty
            selectedGlyph = card.glyph
        }
    }
    
    private func saveCard() {
        let trimmedFront = frontText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = backText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedFront.isEmpty && !trimmedBack.isEmpty else { return }
        
        if let existingCard = card {
            existingCard.frontText = trimmedFront
            existingCard.backText = trimmedBack
            existingCard.difficulty = selectedDifficulty
            existingCard.glyph = selectedGlyph
        } else if let deck = deck {
            let newCard = Card(
                frontText: trimmedFront,
                backText: trimmedBack,
                difficulty: selectedDifficulty,
                glyph: selectedGlyph,
                deck: deck
            )
            modelContext.insert(newCard)
            deck.cards.append(newCard)
        }
        
        do {
            try modelContext.save()
            isPresented = false
        } catch {
            print("Error saving card: \(error)")
        }
    }
}

struct DifficultySelector: View {
    @Binding var selectedDifficulty: Difficulty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyOption(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        action: { selectedDifficulty = difficulty }
                    )
                }
            }
        }
    }
}

struct DifficultyOption: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(difficultyColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                    )
                
                Text(difficulty.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}
