@preconcurrency import CoreSpotlight
import AppIntents
import SwiftData

private let deckSpotlightIndexName = "flipcards-decks"
private let cardSpotlightIndexName = "flipcards-cards"

private var deckSpotlightIndex: CSSearchableIndex {
    CSSearchableIndex(name: deckSpotlightIndexName)
}

private var cardSpotlightIndex: CSSearchableIndex {
    CSSearchableIndex(name: cardSpotlightIndexName)
}

/// Donates all decks and cards to the on-device Spotlight / Apple Intelligence index.
/// Requires iOS 18+ for app-entity indexing. No-op on earlier versions.
func donateToSpotlight(decks: [Deck]) async {
    guard #available(iOS 18.0, *) else { return }

    let deckEntities = decks.map(DeckEntity.init(deck:))
    let cardEntities = decks.flatMap(CardEntity.entities(in:))

    do {
        try await deckSpotlightIndex.deleteAppEntities(ofType: DeckEntity.self)
        try await cardSpotlightIndex.deleteAppEntities(ofType: CardEntity.self)

        if !deckEntities.isEmpty {
            try await deckSpotlightIndex.indexAppEntities(deckEntities)
        }

        if !cardEntities.isEmpty {
            try await cardSpotlightIndex.indexAppEntities(cardEntities)
        }
    } catch {
        print("Error refreshing Spotlight index: \(error)")
    }
}

/// Updates one deck and its cards in Spotlight after a local save.
func donateDeckToSpotlight(_ deck: Deck) async {
    guard #available(iOS 18.0, *) else { return }

    do {
        try await deckSpotlightIndex.indexAppEntities([DeckEntity(deck: deck)])

        let cardEntities = CardEntity.entities(in: deck)
        if !cardEntities.isEmpty {
            try await cardSpotlightIndex.indexAppEntities(cardEntities)
        }
    } catch {
        print("Error updating Spotlight index: \(error)")
    }
}

/// Removes deleted cards from Spotlight immediately so stale results do not remain searchable.
func removeCardsFromSpotlight(identifiedBy cardIDs: [UUID]) async {
    guard #available(iOS 18.0, *), !cardIDs.isEmpty else { return }

    do {
        try await cardSpotlightIndex.deleteAppEntities(identifiedBy: cardIDs, ofType: CardEntity.self)
        try await cardSpotlightIndex.deleteSearchableItems(withIdentifiers: cardIDs.map(\.uuidString))
    } catch {
        print("Error removing cards from Spotlight: \(error)")
    }
}

/// Removes a deleted deck and all of its cards from Spotlight immediately.
func removeDeckFromSpotlight(deckID: UUID, cardIDs: [UUID]) async {
    guard #available(iOS 18.0, *) else { return }

    do {
        try await deckSpotlightIndex.deleteAppEntities(identifiedBy: [deckID], ofType: DeckEntity.self)
        try await deckSpotlightIndex.deleteSearchableItems(withIdentifiers: [deckID.uuidString])

        if !cardIDs.isEmpty {
            try await cardSpotlightIndex.deleteAppEntities(identifiedBy: cardIDs, ofType: CardEntity.self)
            try await cardSpotlightIndex.deleteSearchableItems(withIdentifiers: cardIDs.map(\.uuidString))
        }
    } catch {
        print("Error removing deck from Spotlight: \(error)")
    }
}

/// Fetches decks using a standalone container and donates them to Spotlight.
/// Safe to call without an existing SwiftUI model context (e.g. on background launch).
func refreshSpotlightIndex() async {
    guard #available(iOS 18.0, *) else { return }
    do {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        await donateToSpotlight(decks: decks)
    } catch {
        print("Error loading decks for Spotlight refresh: \(error)")
    }
}

private extension DeckEntity {
    init(deck: Deck) {
        self.init(id: deck.id, name: deck.name, glyph: deck.glyph, cardCount: deck.cards.count)
    }
}

private extension CardEntity {
    static func entities(in deck: Deck) -> [CardEntity] {
        deck.cards.map {
            CardEntity(
                id: $0.id,
                deckId: deck.id,
                frontText: $0.frontText,
                backText: $0.backText,
                deckName: deck.name
            )
        }
    }
}
