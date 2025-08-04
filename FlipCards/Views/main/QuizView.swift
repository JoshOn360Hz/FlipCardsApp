import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let deck: Deck
    
    @State private var currentCardIndex = 0
    @State private var showingAnswer = false
    @State private var quizCards: [Card] = []
    @State private var sessionStats = QuizSession()
    @State private var showingResults = false
    
    var currentCard: Card? {
        guard currentCardIndex < quizCards.count else { return nil }
        return quizCards[currentCardIndex]
    }
    
    var progress: Double {
        guard !quizCards.isEmpty else { return 0 }
        return min(Double(currentCardIndex) / Double(quizCards.count), 1.0)
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
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(min(currentCardIndex + 1, quizCards.count)) of \(quizCards.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: themeManager.cardTheme.accentGlowColor))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                if let card = currentCard {
                    QuizCardView(
                        card: card,
                        showingAnswer: $showingAnswer,
                        onCorrect: { markAnswer(correct: true) },
                        onIncorrect: { markAnswer(correct: false) },
                        onNext: nextCard
                    )
                    .id(card.id) 
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: currentCardIndex)
                } else {
                    QuizCompletedView(
                        stats: sessionStats,
                        onRestart: startQuiz,
                        onFinish: { dismiss() }
                    )
                }
            }
        }
        .navigationTitle("\(deck.name)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End Quiz") {
                    showingResults = true
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            startQuiz()
        }
        .alert("End Quiz?", isPresented: $showingResults) {
            
            Button("End Quiz", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will be saved, but you'll exit the current quiz session.")
        }
    }
    
    private func startQuiz() {
        quizCards = generateWeightedCardOrder(from: deck.cards)
        currentCardIndex = 0
        showingAnswer = false
        sessionStats = QuizSession()
    }
    
    private func generateWeightedCardOrder(from cards: [Card]) -> [Card] {
        if cards.count == 1 {
            return [cards[0]]
        }
        
        var weightedCards: [Card] = []
        
        for card in cards {
            let repetitions = card.difficulty.weight
            for _ in 0..<repetitions {
                weightedCards.append(card)
            }
        }
        
        return shuffleWithoutConsecutiveDuplicates(weightedCards)
    }
    
    private func shuffleWithoutConsecutiveDuplicates(_ cards: [Card]) -> [Card] {
        var shuffled = cards.shuffled()
        
        if shuffled.count < 2 {
            return shuffled
        }
        
        var attempts = 0
        let maxAttempts = 100 
        
        while hasConsecutiveDuplicates(shuffled) && attempts < maxAttempts {
            shuffled = cards.shuffled()
            attempts += 1
        }
        
        if hasConsecutiveDuplicates(shuffled) {
            shuffled = fixConsecutiveDuplicates(shuffled)
        }
        
        return shuffled
    }
    
    private func hasConsecutiveDuplicates(_ cards: [Card]) -> Bool {
        for i in 0..<cards.count - 1 {
            if cards[i].id == cards[i + 1].id {
                return true
            }
        }
        return false
    }
    
    private func fixConsecutiveDuplicates(_ cards: [Card]) -> [Card] {
        var result = cards
        
        var i = 0
        while i < result.count - 1 {
            if result[i].id == result[i + 1].id {
                var swapIndex = -1
                for j in i + 2..<result.count {
                    if result[j].id != result[i].id && 
                       (j == result.count - 1 || result[j].id != result[j + 1].id) &&
                       (i == 0 || result[j].id != result[i - 1].id) {
                        swapIndex = j
                        break
                    }
                }
                
                if swapIndex != -1 {
                    result.swapAt(i + 1, swapIndex)
                } else {
                    let duplicateCard = result.remove(at: i + 1)
                    var insertIndex = result.count
                    
                    for j in (i + 2)..<result.count {
                        if result[j].id != duplicateCard.id &&
                           (j == result.count - 1 || result[j + 1].id != duplicateCard.id) {
                            insertIndex = j + 1
                            break
                        }
                    }
                    
                    result.insert(duplicateCard, at: insertIndex)
                }
            }
            i += 1
        }
        
        return result
    }
    
    private func markAnswer(correct: Bool) {
        guard let card = currentCard else { return }
        
        card.timesReviewed += 1
        card.lastReviewed = Date()
        
        if correct {
            card.timesCorrect += 1
            sessionStats.correctAnswers += 1
        } else {
            sessionStats.incorrectAnswers += 1
        }
        
        sessionStats.totalCards += 1
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving card stats: \(error)")
        }
        
        let delay = card.cardType == .multipleChoice ? 0.15 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            nextCard()
        }
    }
    
    private func nextCard() {
        if currentCardIndex < quizCards.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentCardIndex += 1
                showingAnswer = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentCardIndex = quizCards.count
            }
        }
    }
}

struct QuizCardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let onNext: () -> Void
    
    @State private var showingButtons = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if card.cardType == .multipleChoice {
                MultipleChoiceCardView(
                    card: card,
                    onAnswer: { correct in
                        if correct {
                            onCorrect()
                        } else {
                            onIncorrect()
                        }
                    }
                )
            } else {
                FlashcardView(
                    card: card,
                    showingAnswer: $showingAnswer,
                    showingButtons: $showingButtons,
                    onCorrect: onCorrect,
                    onIncorrect: onIncorrect
                )
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: card.id) { _, _ in
            showingButtons = false
            showingAnswer = false
        }
    }
}

struct FlashcardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    @Binding var showingButtons: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                CardSide(
                    text: card.frontText,
                    title: "Question",
                    difficulty: card.difficulty,
                    glyph: card.glyph,
                    isVisible: !showingAnswer,
                    drawingData: card.frontDrawingData
                )
                .rotation3DEffect(
                    .degrees(showingAnswer ? 90 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                CardSide(
                    text: card.backText,
                    title: "Answer",
                    difficulty: card.difficulty,
                    glyph: card.glyph,
                    isVisible: showingAnswer,
                    drawingData: card.backDrawingData
                )
                .rotation3DEffect(
                    .degrees(showingAnswer ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showingAnswer.toggle()
                }
                
                if showingAnswer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingButtons = true
                        }
                    }
                } else {
                    showingButtons = false
                }
            }
            
            if showingAnswer && showingButtons {
                AnswerButtons(
                    onCorrect: {
                        showingButtons = false
                        onCorrect()
                    },
                    onIncorrect: {
                        showingButtons = false
                        onIncorrect()
                    }
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if !showingAnswer {
                HStack(spacing: 6) {
                    Text("Tap anywhere on the card")
                        .font(.caption)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: themeManager.cardTheme.primaryButtonColors),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .shadow(color: themeManager.cardTheme.accentGlowColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}

struct MultipleChoiceCardView: View {
    let card: Card
    let onAnswer: (Bool) -> Void
    @State private var selectedChoice: Int? = nil
    @State private var hasAnswered = false
    @State private var showingResult = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: card.glyph.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.cardTheme.questionColors[0])
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(themeManager.cardTheme.questionColors[0])
                                .frame(width: 8, height: 8)
                            
                            Text("Multiple Choice")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    DifficultyBadge(difficulty: card.difficulty)
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        Text(card.frontText)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        if let frontDrawingData = card.frontDrawingData {
                            DrawingPreview(
                                drawingData: frontDrawingData,
                                size: CGSize(width: 280, height: 140)
                            )
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius)
                    .fill(themeManager.cardTheme.adaptiveBackgroundColor(for: themeManager.colorScheme))
                    .shadow(color: .black.opacity(0.1), radius: themeManager.cardTheme.shadowRadius, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.cardTheme.questionColors[0].opacity(0.3),
                                themeManager.cardTheme.questionColors[1].opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: themeManager.cardTheme.borderWidth
                    )
            )
            
            VStack(spacing: 12) {
                ForEach(Array(card.multipleChoiceOptions.enumerated()), id: \.offset) { index, option in
                    MultipleChoiceOption(
                        text: option,
                        index: index,
                        isSelected: selectedChoice == index,
                        isCorrect: index == card.correctChoiceIndex,
                        showingResult: showingResult,
                        onTap: {
                            guard !hasAnswered else { return }
                            selectedChoice = index
                            hasAnswered = true
                            
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingResult = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                onAnswer(index == card.correctChoiceIndex)
                            }
                        }
                    )
                }
            }
        }
        .onChange(of: card.id) { _, _ in
            selectedChoice = nil
            hasAnswered = false
            showingResult = false
        }
    }
}

struct MultipleChoiceOption: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let showingResult: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var optionBackground: some View {
        if showingResult {
            if isCorrect {
                return AnyView(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: themeManager.cardTheme.correctButtonColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            } else if isSelected && !isCorrect {
                return AnyView(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: themeManager.cardTheme.incorrectButtonColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        } else if isSelected {
            return AnyView(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: themeManager.cardTheme.primaryButtonColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        return AnyView(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
        )
    }
    
    var textColor: Color {
        if showingResult && (isCorrect || (isSelected && !isCorrect)) {
            return .white
        } else if isSelected {
            return .white
        }
        return .primary
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("\(["A", "B", "C", "D", "E", "F"][index]).")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 30)
                
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if showingResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if showingResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(textColor)
            .padding()
            .background(optionBackground)
        }
        .disabled(showingResult)
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardSide: View {
    let text: String
    let title: String
    let difficulty: Difficulty
    let glyph: DeckGlyph
    let isVisible: Bool
    let drawingData: Data?
    @EnvironmentObject var themeManager: ThemeManager
    
    private var cardColors: [Color] {
        title == "Question" ? themeManager.cardTheme.questionColors : themeManager.cardTheme.answerColors
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: glyph.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(cardColors[0])
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(cardColors[0])
                            .frame(width: 8, height: 8)
                        
                        Text(title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                DifficultyBadge(difficulty: difficulty)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    } else if drawingData != nil {
                        Text("")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    }
                    
                    if let drawingData = drawingData {
                        DrawingPreview(
                            drawingData: drawingData,
                            size: CGSize(width: 280, height: 140),
                            showFullDrawing: true
                        )
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 240)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius)
                .fill(themeManager.cardTheme.adaptiveBackgroundColor(for: themeManager.colorScheme))
                .shadow(color: .black.opacity(0.1), radius: themeManager.cardTheme.shadowRadius, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            cardColors[0].opacity(0.3),
                            cardColors[1].opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: themeManager.cardTheme.borderWidth
                )
        )
        .opacity(isVisible ? 1 : 0)
    }
}

struct AnswerButtons: View {
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onIncorrect) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.headline)
                    Text("Incorrect")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: themeManager.cardTheme.incorrectButtonColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: themeManager.cardTheme.incorrectButtonColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button(action: onCorrect) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                    Text("Correct")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: themeManager.cardTheme.correctButtonColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: themeManager.cardTheme.correctButtonColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct QuizCompletedView: View {
    let stats: QuizSession
    let onRestart: () -> Void
    let onFinish: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: themeManager.cardTheme.primaryButtonColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: themeManager.cardTheme.accentGlowColor.opacity(0.5), radius: 12, x: 0, y: 6)
                    
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                VStack(spacing: 12) {
                    StatisticRow(label: "Total Cards", value: "\(stats.totalCards)")
                    StatisticRow(label: "Correct", value: "\(stats.correctAnswers)")
                    StatisticRow(label: "Incorrect", value: "\(stats.incorrectAnswers)")
                    StatisticRow(label: "Accuracy", value: "\(stats.accuracyPercentage)%")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.6)
                        .fill(themeManager.cardTheme.adaptiveBackgroundColor(for: themeManager.colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.6)
                                .stroke(themeManager.cardTheme.accentGlowColor.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: themeManager.cardTheme.accentGlowColor.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Restart Quiz") {
                        onRestart()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Finish") {
                        onFinish()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct StatisticRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: themeManager.cardTheme.primaryButtonColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(themeManager.cardTheme.cornerRadius * 0.6)
            .shadow(color: themeManager.cardTheme.accentGlowColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(themeManager.cardTheme.accentGlowColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.6)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.cardTheme.cornerRadius * 0.6)
                            .stroke(themeManager.cardTheme.accentGlowColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct QuizSession {
    var totalCards = 0
    var correctAnswers = 0
    var incorrectAnswers = 0
    
    var accuracyPercentage: Int {
        guard totalCards > 0 else { return 0 }
        return Int(Double(correctAnswers) / Double(totalCards) * 100)
    }
}

