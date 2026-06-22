import AppIntents

struct FlipCardsShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenDeckIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target) deck in \(.applicationName)",
                "Open \(\.$target) flashcards in \(.applicationName)"
            ],
            shortTitle: "Open Deck",
            systemImageName: "rectangle.stack.fill"
        )

        AppShortcut(
            intent: StartQuizIntent(),
            phrases: [
                "Quiz me on \(\.$deck) in \(.applicationName)",
                "Start a \(\.$deck) quiz in \(.applicationName)",
                "Study \(\.$deck) in \(.applicationName)"
            ],
            shortTitle: "Start Quiz",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: ShowCardIntent(),
            phrases: [
                "Show \(\.$target) card in \(.applicationName)",
                "Open \(\.$target) in \(.applicationName)",
                "Find \(\.$target) card in \(.applicationName)"
            ],
            shortTitle: "Show Card",
            systemImageName: "rectangle.on.rectangle"
        )
    }
}
