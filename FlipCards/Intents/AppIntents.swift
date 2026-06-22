import AppIntents
import Foundation

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToDeck = Notification.Name("FlipCards.navigateToDeck")
    static let navigateToQuiz = Notification.Name("FlipCards.navigateToQuiz")
    static let navigateToCard = Notification.Name("FlipCards.navigateToCard")
}

private let pendingNavigationKey = "FlipCards.pendingNavigation"

// MARK: - Open Deck Intent
// Conforms to OpenIntent so tapping a deck in Spotlight navigates into the app.

struct OpenDeckIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Deck"
    static var description = IntentDescription("Opens a specific flashcard deck in FlipCards.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Deck", description: "The flashcard deck to open.")
    var target: DeckEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            UserDefaults.standard.set(
                ["type": "deck", "id": target.id.uuidString],
                forKey: pendingNavigationKey
            )
            NotificationCenter.default.post(name: .navigateToDeck, object: target.id)
        }
        return .result()
    }
}

// MARK: - Start Quiz Intent

struct StartQuizIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Quiz"
    static var description = IntentDescription("Starts a quiz session for a specific deck in FlipCards.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Deck", description: "The flashcard deck to quiz on.")
    var deck: DeckEntity

    func perform() async throws -> some IntentResult {
        guard deck.cardCount > 0 else {
            throw $deck.needsValueError("That deck has no cards to quiz on. Add some cards first.")
        }
        await MainActor.run {
            UserDefaults.standard.set(
                ["type": "quiz", "id": deck.id.uuidString],
                forKey: pendingNavigationKey
            )
            NotificationCenter.default.post(name: .navigateToQuiz, object: deck.id)
        }
        return .result()
    }
}

// MARK: - Show Card Intent
// Conforms to OpenIntent so tapping a card in Spotlight navigates into the app.

struct ShowCardIntent: OpenIntent {
    static var title: LocalizedStringResource = "Show Card"
    static var description = IntentDescription("Opens a specific flashcard in FlipCards.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Card", description: "The flashcard to display.")
    var target: CardEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            UserDefaults.standard.set(
                ["type": "card", "cardId": target.id.uuidString, "deckId": target.deckId.uuidString],
                forKey: pendingNavigationKey
            )
            NotificationCenter.default.post(
                name: .navigateToCard,
                object: ["cardId": target.id, "deckId": target.deckId] as [String: UUID]
            )
        }
        return .result()
    }
}
