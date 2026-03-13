import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

class SettingsHelper {
    static func applyColorScheme(_ scheme: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch scheme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        case "system":
            window.overrideUserInterfaceStyle = .unspecified
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    static func iconForScheme(_ scheme: String) -> String {
        switch scheme {
        case "light":
            return "sun.max.fill"
        case "dark":
            return "moon.fill"
        case "system":
            return "circle.lefthalf.filled"
        default:
            return "circle.lefthalf.filled"
        }
    }
    
    static func titleForScheme(_ scheme: String) -> String {
        switch scheme {
        case "light":
            return "Light"
        case "dark":
            return "Dark"
        case "system":
            return "System"
        default:
            return "System"
        }
    }

    nonisolated static func generateCSVExport(from decks: [Deck]) -> CSVExportDocument {
        let header = CSVHeader.allCases.map(\.rawValue).joined(separator: ",")
        let sortedDecks = decks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let rows = sortedDecks.flatMap { deck in
            let sortedCards = deck.cards.sorted {
                $0.frontText.localizedCaseInsensitiveCompare($1.frontText) == .orderedAscending
            }

            if sortedCards.isEmpty {
                return [csvRow(deck: deck, card: nil)]
            }

            return sortedCards.map { card in
                csvRow(deck: deck, card: card)
            }
        }

        let csv = ([header] + rows).joined(separator: "\n")
        return CSVExportDocument(text: csv)
    }

    @discardableResult
    nonisolated static func importCSV(from url: URL, into modelContext: ModelContext) throws -> CSVImportResult {
        let didAccessURL = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessURL {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        guard let csvText = String(data: data, encoding: .utf8) else {
            throw CSVImportError.invalidEncoding
        }

        let rows = parseCSVRows(from: csvText)
        guard let headerRow = rows.first, !headerRow.isEmpty else {
            throw CSVImportError.emptyFile
        }

        let headerLookup = Dictionary(uniqueKeysWithValues: headerRow.enumerated().map { ($0.element, $0.offset) })
        let requiredHeaders = CSVHeader.allCases.map(\.rawValue)
        let missingHeaders = requiredHeaders.filter { headerLookup[$0] == nil }
        guard missingHeaders.isEmpty else {
            throw CSVImportError.missingHeaders(missingHeaders)
        }

        let existingDecks = try modelContext.fetch(FetchDescriptor<Deck>())
        var deckCache = Dictionary(uniqueKeysWithValues: existingDecks.map { ($0.name, $0) })
        var createdDeckCount = 0
        var importedCardCount = 0

        for row in rows.dropFirst() {
            if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            let deckName = value(for: .deckName, in: row, lookup: headerLookup).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !deckName.isEmpty else {
                continue
            }

            let deckGlyph = value(for: .deckGlyph, in: row, lookup: headerLookup)
            let deckBackground = value(for: .deckBackground, in: row, lookup: headerLookup)
            let deck = deckCache[deckName] ?? {
                let newDeck = Deck(
                    name: deckName,
                    glyph: deckGlyph.isEmpty ? "rectangle.stack.fill" : deckGlyph,
                    backgroundColor: deckBackground.isEmpty ? "blue" : deckBackground
                )

                let createdDateValue = value(for: .createdDate, in: row, lookup: headerLookup)
                if let createdDate = iso8601Date(from: createdDateValue) {
                    newDeck.createdDate = createdDate
                }

                modelContext.insert(newDeck)
                deckCache[deckName] = newDeck
                createdDeckCount += 1
                return newDeck
            }()

            let cardFront = value(for: .cardFront, in: row, lookup: headerLookup)
            let cardBack = value(for: .cardBack, in: row, lookup: headerLookup)
            let cardTypeValue = value(for: .cardType, in: row, lookup: headerLookup)
            let cardDifficultyValue = value(for: .cardDifficulty, in: row, lookup: headerLookup)
            let cardGlyphValue = value(for: .cardGlyph, in: row, lookup: headerLookup)
            let optionsValue = value(for: .multipleChoiceOptions, in: row, lookup: headerLookup)

            let hasCardPayload = !cardFront.isEmpty || !cardBack.isEmpty || !cardTypeValue.isEmpty || !cardDifficultyValue.isEmpty || !cardGlyphValue.isEmpty || !optionsValue.isEmpty
            guard hasCardPayload else {
                continue
            }

            let difficulty = Difficulty(rawValue: cardDifficultyValue) ?? .medium
            let glyph = DeckGlyph(rawValue: cardGlyphValue) ?? .lightbulb
            let cardType = CardType(rawValue: cardTypeValue) ?? .flashcard

            let card = Card(
                frontText: cardFront,
                backText: cardBack,
                difficulty: difficulty,
                glyph: glyph,
                deck: deck,
                cardType: cardType
            )

            card.multipleChoiceOptions = optionsValue.isEmpty ? [] : optionsValue.components(separatedBy: "||")
            card.correctChoiceIndex = Int(value(for: .correctChoiceIndex, in: row, lookup: headerLookup)) ?? 0
            card.timesReviewed = Int(value(for: .timesReviewed, in: row, lookup: headerLookup)) ?? 0
            card.timesCorrect = Int(value(for: .timesCorrect, in: row, lookup: headerLookup)) ?? 0
            card.lastReviewed = iso8601Date(from: value(for: .lastReviewed, in: row, lookup: headerLookup))

            modelContext.insert(card)
            deck.cards.append(card)
            importedCardCount += 1
        }

        try modelContext.save()
        return CSVImportResult(createdDecks: createdDeckCount, importedCards: importedCardCount)
    }

    nonisolated private static func value(for header: CSVHeader, in row: [String], lookup: [String: Int]) -> String {
        guard let index = lookup[header.rawValue], row.indices.contains(index) else {
            return ""
        }

        return row[index]
    }

    nonisolated private static func csvRow(deck: Deck, card: Card?) -> String {
        [
            escapeCSVField(deck.name),
            escapeCSVField(deck.glyph),
            escapeCSVField(deck.backgroundColor),
            escapeCSVField(card?.frontText ?? ""),
            escapeCSVField(card?.backText ?? ""),
            escapeCSVField(card?.cardType.rawValue ?? ""),
            escapeCSVField(card?.difficulty.rawValue ?? ""),
            escapeCSVField(card?.glyph.rawValue ?? ""),
            escapeCSVField(card?.multipleChoiceOptions.joined(separator: "||") ?? ""),
            escapeCSVField(card.map { String($0.correctChoiceIndex) } ?? ""),
            escapeCSVField(card.map { String($0.timesReviewed) } ?? ""),
            escapeCSVField(card.map { String($0.timesCorrect) } ?? ""),
            escapeCSVField(card?.lastReviewed.map(Self.iso8601String) ?? ""),
            escapeCSVField(iso8601String(deck.createdDate))
        ].joined(separator: ",")
    }

    nonisolated private static func escapeCSVField(_ value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escapedValue.contains(",") || escapedValue.contains("\"") || escapedValue.contains("\n") {
            return "\"\(escapedValue)\""
        }

        return escapedValue
    }

    nonisolated private static func parseCSVRows(from text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var isInsideQuotes = false
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            let character = text[currentIndex]

            if isInsideQuotes {
                if character == "\"" {
                    let nextIndex = text.index(after: currentIndex)
                    if nextIndex < text.endIndex, text[nextIndex] == "\"" {
                        currentField.append("\"")
                        currentIndex = nextIndex
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    currentField.append(character)
                }
            } else {
                switch character {
                case "\"":
                    isInsideQuotes = true
                case ",":
                    currentRow.append(currentField)
                    currentField = ""
                case "\n":
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                case "\r":
                    break
                default:
                    currentField.append(character)
                }
            }

            currentIndex = text.index(after: currentIndex)
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }

    nonisolated private static func iso8601String(_ date: Date) -> String {
        makeCSVDateFormatter().string(from: date)
    }

    nonisolated private static func iso8601Date(from value: String) -> Date? {
        guard !value.isEmpty else {
            return nil
        }

        return makeCSVDateFormatter().date(from: value)
    }

    nonisolated private static func makeCSVDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

enum CSVHeader: String, CaseIterable {
    case deckName = "deck_name"
    case deckGlyph = "deck_glyph"
    case deckBackground = "deck_background"
    case cardFront = "card_front"
    case cardBack = "card_back"
    case cardType = "card_type"
    case cardDifficulty = "card_difficulty"
    case cardGlyph = "card_glyph"
    case multipleChoiceOptions = "multiple_choice_options"
    case correctChoiceIndex = "correct_choice_index"
    case timesReviewed = "times_reviewed"
    case timesCorrect = "times_correct"
    case lastReviewed = "last_reviewed"
    case createdDate = "created_date"
}

struct CSVImportResult {
    let createdDecks: Int
    let importedCards: Int
}

enum CSVImportError: LocalizedError {
    case emptyFile
    case invalidEncoding
    case missingHeaders([String])

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .invalidEncoding:
            return "The CSV file could not be read as UTF-8 text."
        case .missingHeaders(let headers):
            return "The CSV file is missing required columns: \(headers.joined(separator: ", "))"
        }
    }
}

struct CSVExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CSVImportError.invalidEncoding
        }

        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
