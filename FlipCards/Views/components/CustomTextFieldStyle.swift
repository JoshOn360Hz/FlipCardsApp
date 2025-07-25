import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .background(Color(.systemGray4))
                    .offset(y: 6)
                , alignment: .bottom
            )
    }
}
