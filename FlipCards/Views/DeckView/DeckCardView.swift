import SwiftUI

struct DeckCardView: View {
    let deck: Deck
    @EnvironmentObject var themeManager: ThemeManager
    
    private var deckColor: Color {
        DeckBackgroundColor(rawValue: deck.backgroundColor)?.color ?? themeManager.accentColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [deckColor.opacity(0.8), deckColor.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: deck.glyph)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
                
                Text("\(deck.cards.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(deckColor.opacity(0.8))
                    )
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 8) 
            
            VStack(alignment: .leading, spacing: 8) {
                Text(deck.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                Text("Created \(deck.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if deck.cards.count > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor)
                        Text("Ready to study")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor.opacity(0.8))
                        Text("Add cards")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor.opacity(0.8))
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(deckColor, lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}
