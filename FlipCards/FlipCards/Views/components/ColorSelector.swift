import SwiftUI

struct ColorSelector: View {
    @Binding var selectedColor: DeckBackgroundColor
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(DeckBackgroundColor.allCases, id: \.self) { color in
                Button(action: { selectedColor = color }) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                        )
                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}
