import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [themeManager.accentColor.opacity(0.1), themeManager.accentColor.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                
                VStack(spacing: 8) {
                    Text("No Decks Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Create your first deck to start making flashcards")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
