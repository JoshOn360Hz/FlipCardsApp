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
        return Double(currentCardIndex) / Double(quizCards.count)
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
                        Text("\(currentCardIndex + 1) of \(quizCards.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: themeManager.accentColor))
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
            Button("Continue") { }
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
        var weightedCards: [Card] = []
        
        for card in cards {
            let repetitions = card.difficulty.weight
            for _ in 0..<repetitions {
                weightedCards.append(card)
            }
        }
        
        return weightedCards.shuffled()
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            nextCard()
        }
    }
    
    private func nextCard() {
        if currentCardIndex < quizCards.count - 1 {
            currentCardIndex += 1
            showingAnswer = false
        } else {
            currentCardIndex = quizCards.count
        }
    }
}

struct QuizCardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let onNext: () -> Void
    
    @State private var cardRotation: Double = 0
    @State private var showingButtons = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                CardSide(
                    text: card.frontText,
                    title: "Question",
                    difficulty: card.difficulty,
                    glyph: card.glyph,
                    isVisible: !showingAnswer
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
                    isVisible: showingAnswer
                )
                .rotation3DEffect(
                    .degrees(showingAnswer ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .onTapGesture {
                if !showingAnswer {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showingAnswer = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingButtons = true
                        }
                    }
                }
            }
            
            Spacer()
            
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
                .transition(.scale.combined(with: .opacity))
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
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    HStack(spacing: 4) {
                      
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .onChange(of: card.id) { _, _ in
            showingButtons = false
        }
    }
}

struct CardSide: View {
    let text: String
    let title: String
    let difficulty: Difficulty
    let glyph: DeckGlyph
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
                HStack {
                HStack(spacing: 8) {
                    Image(systemName: glyph.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(title == "Question" ? .blue : .green)
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
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .frame(maxHeight: 300)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 240)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            title == "Question" ? .blue.opacity(0.3) : .green.opacity(0.3),
                            title == "Question" ? .purple.opacity(0.3) : .teal.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .opacity(isVisible ? 1 : 0)
    }
}

struct AnswerButtons: View {
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.red, .pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.green, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct QuizCompletedView: View {
    let stats: QuizSession
    let onRestart: () -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
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
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
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
