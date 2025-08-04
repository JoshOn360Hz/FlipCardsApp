import SwiftUI

struct GlyphSelector: View {
    @Binding var selectedGlyph: DeckGlyph
    @EnvironmentObject var themeManager: ThemeManager
    var showTitle: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showTitle {
                Text("Icon")
                    .font(.headline)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DeckGlyph.allCases, id: \.self) { glyph in
                        Button(action: { selectedGlyph = glyph }) {
                            Image(systemName: glyph.rawValue)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedGlyph == glyph ? themeManager.accentColor.opacity(0.2) : Color(.systemGray6))
                                )
                                .foregroundColor(selectedGlyph == glyph ? themeManager.accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
