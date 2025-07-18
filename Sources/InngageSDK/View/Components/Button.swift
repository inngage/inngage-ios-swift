import SwiftUI

struct IButton: View {
    var label: String
    var colorBg: String
    var colorFont: String
    @Binding var isActive: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            isActive = false
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20).foregroundColor(Color(hex: colorHex(color: colorBg)))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: colorHex(color: colorFont)))
                    .padding(10)
            }
            .padding(5)
        }
    }
    
    private func colorHex(color: String) -> String {
        return color.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    }
}

//#Preview {
//    IButton(label: "texto botão", action: {})
//}
