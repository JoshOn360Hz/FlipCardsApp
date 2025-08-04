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
    @State private var selectedCardType: CardType = .flashcard
    @State private var mcOptions: [String] = ["", "", "", ""]
    @State private var correctAnswerIndex = 0
    @State private var frontDrawingData: Data? = nil
    @State private var backDrawingData: Data? = nil
    @State private var showingFrontDrawing = false
    @State private var showingBackDrawing = false
    
    private var isEditing: Bool {
        card != nil
    }
    
    private var canSave: Bool {
        let frontEmpty = frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let backEmpty = backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasFrontDrawing = frontDrawingData != nil
        let hasBackDrawing = backDrawingData != nil
        
        switch selectedCardType {
        case .flashcard:
            let frontHasContent = !frontEmpty || hasFrontDrawing
            let backHasContent = !backEmpty || hasBackDrawing
            return frontHasContent && backHasContent
        case .multipleChoice:
            let hasQuestion = !frontEmpty || hasFrontDrawing
            let filledOptions = mcOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let hasValidOptions = filledOptions.count >= 2
            let correctIndexValid = correctAnswerIndex < filledOptions.count && !mcOptions[correctAnswerIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasQuestion && hasValidOptions && correctIndexValid
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Type")
                            .font(.headline)
                        
                        Picker("Card Type", selection: $selectedCardType) {
                            ForEach(CardType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedCardType == .multipleChoice ? "Question" : "Front (Question)")
                            .font(.headline)
                        
                        ZStack(alignment: .topTrailing) {
                            TextEditor(text: $frontText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            DrawingButton(
                                action: { showingFrontDrawing = true },
                                hasDrawing: frontDrawingData != nil
                            )
                            .padding(8)
                        }
                        
                        if let frontDrawingData = frontDrawingData {
                            DrawingPreview(
                                drawingData: frontDrawingData,
                                size: CGSize(width: 300, height: 150),
                                showFullDrawing: true,
                                onDelete: {
                                    self.frontDrawingData = nil
                                },
                                drawingBinding: $frontDrawingData
                            )
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    
                    if selectedCardType == .flashcard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Back (Answer)")
                                .font(.headline)
                            
                            ZStack(alignment: .topTrailing) {
                                TextEditor(text: $backText)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                                
                                DrawingButton(
                                    action: { showingBackDrawing = true },
                                    hasDrawing: backDrawingData != nil
                                )
                                .padding(8)
                            }
                            
                            if let backDrawingData = backDrawingData {
                                DrawingPreview(
                                    drawingData: backDrawingData,
                                    size: CGSize(width: 300, height: 150),
                                    showFullDrawing: true,
                                    onDelete: {
                                        self.backDrawingData = nil
                                    },
                                    drawingBinding: $backDrawingData
                                )
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    if selectedCardType == .multipleChoice {
                        MultipleChoiceEditor(
                            options: $mcOptions,
                            correctIndex: $correctAnswerIndex
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
                    .disabled(!canSave)
                }
            }
        }
        .onChange(of: selectedCardType) { _, newType in
            if newType == .multipleChoice {
                backText = ""
            } else {
                mcOptions = ["", "", "", ""]
                correctAnswerIndex = 0
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .sheet(isPresented: $showingFrontDrawing) {
            DrawingSheet(
                isPresented: $showingFrontDrawing,
                drawingData: $frontDrawingData,
                title: selectedCardType == .multipleChoice ? "Draw on Question" : "Draw on Front"
            )
        }
        .sheet(isPresented: $showingBackDrawing) {
            DrawingSheet(
                isPresented: $showingBackDrawing,
                drawingData: $backDrawingData,
                title: "Draw on Back"
            )
        }
    }
    
    private func setupInitialValues() {
        if let card = card {
            frontText = card.frontText
            backText = card.backText
            selectedDifficulty = card.difficulty
            selectedGlyph = card.glyph
            selectedCardType = card.cardType
            frontDrawingData = card.frontDrawingData
            backDrawingData = card.backDrawingData
            
            if card.cardType == .multipleChoice {
                let existingOptions = card.multipleChoiceOptions
                for i in 0..<4 {
                    mcOptions[i] = i < existingOptions.count ? existingOptions[i] : ""
                }
                let correctAnswer = existingOptions.indices.contains(card.correctChoiceIndex) ? existingOptions[card.correctChoiceIndex] : ""
                correctAnswerIndex = mcOptions.firstIndex(of: correctAnswer) ?? 0
            }
        }
    }
    
    private func saveCard() {
        let trimmedFront = frontText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = backText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalFrontText = trimmedFront
        let finalBackText = trimmedBack
        
        guard canSave else { return }
        
        if let existingCard = card {
            existingCard.frontText = finalFrontText
            existingCard.difficulty = selectedDifficulty
            existingCard.glyph = selectedGlyph
            existingCard.cardType = selectedCardType
            existingCard.frontDrawingData = frontDrawingData
            existingCard.backDrawingData = backDrawingData
            
            if selectedCardType == .flashcard {
                existingCard.backText = finalBackText
                existingCard.multipleChoiceOptions = []
                existingCard.correctChoiceIndex = 0
            } else {
                existingCard.backText = mcOptions[correctAnswerIndex]
                let filledOptions = mcOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                existingCard.multipleChoiceOptions = filledOptions
                existingCard.correctChoiceIndex = filledOptions.firstIndex(of: mcOptions[correctAnswerIndex]) ?? 0
            }
        } else if let deck = deck {
            let newCard = Card(
                frontText: finalFrontText,
                backText: selectedCardType == .flashcard ? finalBackText : mcOptions[correctAnswerIndex],
                difficulty: selectedDifficulty,
                glyph: selectedGlyph,
                deck: deck,
                cardType: selectedCardType
            )
            
            newCard.frontDrawingData = frontDrawingData
            newCard.backDrawingData = backDrawingData
            
            if selectedCardType == .multipleChoice {
                let filledOptions = mcOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                newCard.multipleChoiceOptions = filledOptions
                newCard.correctChoiceIndex = filledOptions.firstIndex(of: mcOptions[correctAnswerIndex]) ?? 0
            }
            
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

struct MultipleChoiceEditor: View {
    @Binding var options: [String]
    @Binding var correctIndex: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Answer Choices")
                .font(.headline)
            
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                HStack {
                    Button(action: {
                        correctIndex = index
                    }) {
                        Image(systemName: correctIndex == index ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(correctIndex == index ? themeManager.accentColor : .gray)
                    }
                    
                    TextField("Choice \(["A", "B", "C", "D"][index])", text: Binding(
                        get: { options[index] },
                        set: { options[index] = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Text("Tap the circle to mark the correct answer")
                .font(.caption)
                .foregroundColor(.secondary)
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
