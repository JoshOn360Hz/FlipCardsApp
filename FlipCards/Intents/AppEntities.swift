import AppIntents
import CoreSpotlight
import SwiftData
import Foundation

// MARK: - DeckEntity

struct DeckEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Deck"
    static var defaultQuery = DeckEntityQuery()

    let id: UUID
    let name: String
    let glyph: String
    let cardCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(cardCount) card\(cardCount == 1 ? "" : "s")"
        )
    }

    // Spotlight indexes displayRepresentation automatically; attributeSet adds richer metadata
    var attributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = name
        attrs.contentDescription = "\(cardCount) card\(cardCount == 1 ? "" : "s") · FlipCards deck"
        attrs.keywords = [name, "deck", "flashcard", "study"]
        return attrs
    }
}

// MARK: - DeckEntityQuery

struct DeckEntityQuery: EntityStringQuery {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([Deck.self, Card.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func entities(for identifiers: [UUID]) async throws -> [DeckEntity] {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        return decks
            .filter { identifiers.contains($0.id) }
            .map { DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count) }
    }

    func entities(matching string: String) async throws -> [DeckEntity] {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        let filtered = string.isEmpty ? decks : decks.filter {
            $0.name.localizedCaseInsensitiveContains(string)
        }
        return filtered.map { DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count) }
    }

    func suggestedEntities() async throws -> [DeckEntity] {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        return decks.map { DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count) }
    }
}

// IndexedEntityQuery conformance requires CSSearchableIndexDescription (iOS 27+)
@available(iOS 27.0, *)
extension DeckEntityQuery: IndexedEntityQuery {
    // Called by the system when Spotlight needs to rebuild its full index
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        let entities = decks.map { DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count) }
        try await CSSearchableIndex(name: "flipcards-decks").indexAppEntities(entities)
    }

    func reindexEntities(for identifiers: [UUID], indexDescription: CSSearchableIndexDescription) async throws {
        let container = try DeckEntityQuery.makeContainer()
        let context = ModelContext(container)
        let decks = try context.fetch(FetchDescriptor<Deck>())
        let entities = decks
            .filter { identifiers.contains($0.id) }
            .map { DeckEntity(id: $0.id, name: $0.name, glyph: $0.glyph, cardCount: $0.cards.count) }
        try await CSSearchableIndex(name: "flipcards-decks").indexAppEntities(entities)
    }
}

// MARK: - CardEntity

struct CardEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Card"
    static var defaultQuery = CardEntityQuery()

    let id: UUID
    let deckId: UUID
    let frontText: String
    let backText: String
    let deckName: String

    var displayRepresentation: DisplayRepresentation {
        let title = frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Drawing Card"
            : frontText
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "in \(deckName)"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        let displayTitle = frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Drawing Card" : frontText
        attrs.title = displayTitle
        // Indexing the back text means people can find cards by their answer, not just the question
        attrs.contentDescription = backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "in \(deckName)"
            : "\(backText) · \(deckName)"
        attrs.subject = deckName
        attrs.keywords = [frontText, backText, deckName, "flashcard", "card"].filter { !$0.isEmpty }
        return attrs
    }
}

// MARK: - CardEntityQuery

struct CardEntityQuery: EntityStringQuery {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([Deck.self, Card.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func entities(for identifiers: [UUID]) async throws -> [CardEntity] {
        let container = try CardEntityQuery.makeContainer()
        let context = ModelContext(container)
        let cards = try context.fetch(FetchDescriptor<Card>())
        return cards
            .filter { identifiers.contains($0.id) }
            .compactMap { card -> CardEntity? in
                guard let deck = card.deck else { return nil }
                return CardEntity(id: card.id, deckId: deck.id, frontText: card.frontText, backText: card.backText, deckName: deck.name)
            }
    }

    func entities(matching string: String) async throws -> [CardEntity] {
        let container = try CardEntityQuery.makeContainer()
        let context = ModelContext(container)
        let cards = try context.fetch(FetchDescriptor<Card>())
        let filtered = string.isEmpty ? cards : cards.filter {
            $0.frontText.localizedCaseInsensitiveContains(string) ||
            $0.backText.localizedCaseInsensitiveContains(string)
        }
        return filtered.compactMap { card -> CardEntity? in
            guard let deck = card.deck else { return nil }
            return CardEntity(id: card.id, deckId: deck.id, frontText: card.frontText, backText: card.backText, deckName: deck.name)
        }
    }

    func suggestedEntities() async throws -> [CardEntity] {
        let container = try CardEntityQuery.makeContainer()
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Card>()
        descriptor.fetchLimit = 20
        let cards = try context.fetch(descriptor)
        return cards.compactMap { card -> CardEntity? in
            guard let deck = card.deck else { return nil }
            return CardEntity(id: card.id, deckId: deck.id, frontText: card.frontText, backText: card.backText, deckName: deck.name)
        }
    }
}

@available(iOS 27.0, *)
extension CardEntityQuery: IndexedEntityQuery {
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        let container = try CardEntityQuery.makeContainer()
        let context = ModelContext(container)
        let cards = try context.fetch(FetchDescriptor<Card>())
        let entities = cards.compactMap { card -> CardEntity? in
            guard let deck = card.deck else { return nil }
            return CardEntity(id: card.id, deckId: deck.id, frontText: card.frontText, backText: card.backText, deckName: deck.name)
        }
        try await CSSearchableIndex(name: "flipcards-cards").indexAppEntities(entities)
    }

    func reindexEntities(for identifiers: [UUID], indexDescription: CSSearchableIndexDescription) async throws {
        let container = try CardEntityQuery.makeContainer()
        let context = ModelContext(container)
        let cards = try context.fetch(FetchDescriptor<Card>())
        let entities = cards
            .filter { identifiers.contains($0.id) }
            .compactMap { card -> CardEntity? in
                guard let deck = card.deck else { return nil }
                return CardEntity(id: card.id, deckId: deck.id, frontText: card.frontText, backText: card.backText, deckName: deck.name)
            }
        try await CSSearchableIndex(name: "flipcards-cards").indexAppEntities(entities)
    }
}
