import SwiftUI

struct DeckCardView: View {
    let deck: Deck
    
    private var deckColor: Color {
        DeckBackgroundColor(rawValue: deck.backgroundColor)?.color ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and count
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
            
            // Content
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
                            .foregroundColor(.green)
                        Text("Ready to study")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Add cards")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}
