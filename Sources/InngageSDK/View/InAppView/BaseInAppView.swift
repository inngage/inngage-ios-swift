import SwiftUI

struct BaseInAppView<Content: View>: View {
    @Binding var isActive: Bool
    var data: [String: Any]?
    
    @State private var offsetY: CGFloat = UIScreen.main.bounds.height * 0.1
    @State private var blurRadius: CGFloat = 20
    
    var actionButtonRight: () -> Void = {}
    var actionButtonLeft: () -> Void = {}
    
    @State private var title: String = ""
    @State private var ibody: String = ""
    @State private var titleFontColor: String = ""
    @State private var bodyFontColor: String = ""
    
    @State private var btnLeftText: String = ""
    @State private var btnLeftTextColor: String = ""
    @State private var btnLeftBgColor: String = ""
    @State private var btnLeftActionType: String = ""
    @State private var btnLeftActionLink: String = ""
    
    @State private var btnRightText: String = ""
    @State private var btnRightTextColor: String = ""
    @State private var btnRightBgColor: String = ""
    @State private var btnRightActionType: String = ""
    @State private var btnRightActionLink: String = ""
    
    @State private var backgroundColor: String = ""
    
    @State private var img1: String = ""
    @State private var img2: String = ""
    @State private var img3: String = ""
    @State private var img4: String = ""
    @State private var img5: String = ""
    
    private var weblink: Bool = true
    
    @State private var items: [Item] = []
    
    let content: () -> Content
    
    var body: some View {
        ZStack {
            backgroundOverlay
            content()
                .frame(minWidth: UIScreen.main.bounds.width * 0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(Color(hex: colorHex(color: backgroundColor)))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(closeButtonOverlay)
                .shadow(radius: 20)
                .padding(20)
                .offset(y: offsetY)
                .blur(radius: blurRadius)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.15), value: offsetY)
                .onAppear(perform: open)
        }
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                withAnimation { close() }
            }
    }
    
    private func colorHex(color: String) -> String {
        return color.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    }

    private var closeButtonOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation { close() }
                } label: {
                    if #available(iOS 16.0, *) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.medium)
                            .tint(Color(hex: titleFontColor))
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    private func open() {
        offsetY = 0
        blurRadius = 0
    }

    private func close() {
        offsetY = UIScreen.main.bounds.height * 0.1
        blurRadius = 50
        isActive = false
    }
}
