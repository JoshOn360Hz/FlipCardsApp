@preconcurrency import CoreSpotlight
import AppIntents
import SwiftData

/// Donates all decks and cards to the on-device Spotlight / Apple Intelligence index.
/// Requires iOS 18+ for CSSearchableItem(appEntity:). No-op on earlier versions.
func donateToSpotlight(decks: [Deck]) async {
    guard #available(iOS 18.0, *) else { return }

    let deckEntities = decks.map {
        DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count)
    }

    let cardEntities = decks.flatMap { deck in
        deck.cards.compactMap { card -> CardEntity? in
            CardEntity(
                id: card.id,
                deckId: deck.id,
                frontText: card.frontText,
                backText: card.backText,
                deckName: deck.name
            )
        }
    }

    let deckItems = deckEntities.map { CSSearchableItem(appEntity: $0) }
    let cardItems = cardEntities.map { CSSearchableItem(appEntity: $0) }

    try? await CSSearchableIndex(name: "flipcards-decks").indexSearchableItems(deckItems)
    try? await CSSearchableIndex(name: "flipcards-cards").indexSearchableItems(cardItems)
}
