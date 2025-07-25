import Foundation
import SwiftData
import SwiftUI

@Model
class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var glyph: String
    var backgroundColor: String
    var createdDate: Date
    @Relationship(deleteRule: .cascade, inverse: \Card.deck) var cards: [Card]
    
    init(name: String, glyph: String = "rectangle.stack.fill", backgroundColor: String = "blue") {
        self.id = UUID()
        self.name = name
        self.glyph = glyph
        self.backgroundColor = backgroundColor
        self.createdDate = Date()
        self.cards = []
    }
}

@Model
class Card {
    @Attribute(.unique) var id: UUID
    var frontText: String
    var backText: String
    var difficulty: Difficulty
    var glyph: DeckGlyph
    var deck: Deck?
    var timesReviewed: Int
    var timesCorrect: Int
    var lastReviewed: Date?
    
    init(frontText: String, backText: String, difficulty: Difficulty = .medium, glyph: DeckGlyph = .lightbulb, deck: Deck? = nil) {
        self.id = UUID()
        self.frontText = frontText
        self.backText = backText
        self.difficulty = difficulty
        self.glyph = glyph
        self.deck = deck
        self.timesReviewed = 0
        self.timesCorrect = 0
        self.lastReviewed = nil
    }
    
    var correctPercentage: Double {
        guard timesReviewed > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesReviewed) * 100
    }
}

enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var weight: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

enum DeckGlyph: String, CaseIterable, Codable {
    case books = "books.vertical.fill"
    case calculator = "function"
    case globe = "globe"
    case atom = "atom"
    case dna = "fossil.shell.fill"
    case paintbrush = "paintbrush.fill"
    case music = "music.note"
    case heart = "heart.fill"
    case brain = "brain.head.profile"
    case graduation = "graduationcap.fill"
    case computerScience = "desktopcomputer"
    case coding = "chevron.left.forwardslash.chevron.right"
    case network = "network"
    case database = "externaldrive.fill"
    case gear = "gearshape.fill"
    case circuit = "cpu.fill"
    case language = "character.book.closed.fill"
    case writing = "pencil.and.outline"
    case book = "book.fill"
    case dictionary = "text.book.closed.fill"
    case chemistry = "testtube.2"
    case physics = "waveform.path.ecg"
    case biology = "leaf.fill"
    case history = "clock.fill"
    case economics = "chart.line.uptrend.xyaxis"
    case law = "scale.3d"
    case politics = "building.columns.fill"
    case camera = "camera.fill"
    case palette = "paintpalette.fill"
    case theater = "theatermasks.fill"
    case design = "paintbrush.pointed.fill"
    case sports = "figure.run"
    case fitness = "dumbbell.fill"
    case medicine = "cross.fill"
    case nutrition = "leaf.circle.fill"
    case star = "star.fill"
    case lightbulb = "lightbulb.fill"
    case target = "target"
    case flag = "flag.fill"
}

enum DeckBackgroundColor: String, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"
    case yellow = "yellow"
    case mint = "mint"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        case .mint: return .mint
        }
    }
}

