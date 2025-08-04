import SwiftUI

struct AddDeckSheet: View {
    @Binding var isPresented: Bool
    @Binding var deckName: String
    let onSave: () -> Void
    @Binding var selectedGlyph: DeckGlyph
    @Binding var selectedBackground: DeckBackgroundColor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [selectedBackground.color.opacity(0.2), selectedBackground.color.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: selectedGlyph.rawValue)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(selectedBackground.color)
                        }
                        
                        Text("Create New Deck")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Deck Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter deck name", text: $deckName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            GlyphSelector(selectedGlyph: $selectedGlyph, showTitle: false)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ColorSelector(selectedColor: $selectedBackground)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        deckName = ""
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createDeck()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .disabled(deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createDeck() {
        onSave()
    }
}
