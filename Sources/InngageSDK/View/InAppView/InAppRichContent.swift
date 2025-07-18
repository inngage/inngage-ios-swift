import SwiftUI
import SDWebImageSwiftUI

struct InAppRichContent: View {
    @Binding var isActive: Bool
    var data: [String: Any]?
    
    @State private var offsetY: CGFloat = UIScreen.main.bounds.height * 0.1
    @State private var blurRadius: CGFloat = 20
    
    var actionButtonRight: () -> Void = {}
    var hasActionButtonRight: Bool
    var actionButtonLeft: () -> Void = {}
    var hasActionButtonLeft: Bool
    
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
    @State private var impression: String = ""
    
    @State private var img1: String = ""
    @State private var img2: String = ""
    @State private var img3: String = ""
    @State private var img4: String = ""
    @State private var img5: String = ""
    
    @State private var imageAspectRatio: CGFloat = 1.0
    @State private var imageHeight: CGFloat? = nil
    @State private var imageWidth: CGFloat? = nil
    @State private var maxImageHeight: CGFloat = 0 // Armazena a altura máxima
    
    private var weblink: Bool = true
    
    @State private var items: [Item] = []

    public init(
        data: [String: Any],
        isActive: Binding<Bool>,
        actionButtonLeft: @escaping () -> Void = {},
        hasActionButtonLeft: Bool = false,
        actionButtonRight: @escaping () -> Void = {},
        hasActionButtonRight: Bool = false) {
            self.actionButtonLeft = actionButtonLeft
            self.actionButtonRight = actionButtonRight
            self.hasActionButtonLeft = hasActionButtonLeft
            self.hasActionButtonRight = hasActionButtonRight
            
            self._isActive = isActive
            self.data = data
            
            let parsedData = parseData(data)
            print(parsedData)
            
            if let inapp = parseAdditionalData(from: data),
               let richContent = inapp["rich_content"] as? [String: Any] {
                self._title = State(initialValue: parsedData.title)
                self._titleFontColor = State(initialValue: inapp["title_font_color"] as? String ?? "")
                self._ibody = State(initialValue: inapp["body"] as? String ?? "")
                self._bodyFontColor = State(initialValue: inapp["body_font_color"] as? String ?? "")
                
                self._btnLeftText = State(initialValue: inapp["btn_left_txt"] as? String ?? "")
                self._btnLeftTextColor = State(initialValue: inapp["btn_left_txt_color"] as? String ?? "")
                self._btnLeftBgColor = State(initialValue: inapp["btn_left_bg_color"] as? String ?? "")
                self._btnLeftActionLink = State(initialValue: inapp["btn_left_action_link"] as? String ?? "")
                self._btnLeftActionType = State(initialValue: inapp["btn_left_action_type"] as? String ?? "")
                
                self._btnRightText = State(initialValue: inapp["btn_right_txt"] as? String ?? "")
                self._btnRightTextColor = State(initialValue: inapp["btn_right_txt_color"] as? String ?? "")
                self._btnRightBgColor = State(initialValue: inapp["btn_right_bg_color"] as? String ?? "")
                self._btnRightActionLink = State(initialValue: inapp["btn_right_action_link"] as? String ?? "")
                self._btnRightActionType = State(initialValue: inapp["btn_right_action_type"] as? String ?? "")
                
                self._backgroundColor = State(initialValue: inapp["background_color"] as? String ?? "")
                self._impression = State(initialValue: inapp["inpression"] as? String ?? "")
                
                self._img1 = State(initialValue: richContent["img1"] as? String ?? "")
                self._img2 = State(initialValue: richContent["img2"] as? String ?? "")
                self._img3 = State(initialValue: richContent["img3"] as? String ?? "")
                self._img4 = State(initialValue: richContent["img4"] as? String ?? "")
                self._img5 = State(initialValue: richContent["img5"] as? String ?? "")
            }
    }
    
    var body: some View {
        backgroundOverlay
        content
            .frame(minWidth: UIScreen.main.bounds.width * 0.8)
            .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            .padding()
            .background(Color(hex: colorHex(color: backgroundColor)))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(20)
            .offset(y: offsetY)
            .blur(radius: blurRadius)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.15), value: offsetY)
            .onAppear(perform: open)
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                withAnimation { close() }
            }
    }
    
    private func calculateContentHeight() -> CGFloat {
        let contentWidth = UIScreen.main.bounds.width * 0.8
        return contentWidth / imageAspectRatio
    }
    
    private var content: some View {
        VStack{
            Carrousel(data: $items) { $item in
                WebImage(url: URL(string: item.image))
                    .onSuccess { image, _, _ in
                        let height = image.size.height
                        let width = image.size.width
                        
                        DispatchQueue.main.async {
                            imageAspectRatio = width / height
                            
                            // Verifica se a imagem atual tem a maior altura
                            if height > self.maxImageHeight {
                                self.maxImageHeight = height
                            }
                            
                            self.imageHeight = height
                            self.imageWidth = width
                        }
                    }
                    .resizable()
                    .scaledToFill() // Para garantir que a imagem preencha o espaço proporcionalmente
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: calculateContentHeight())
                    .cornerRadius(25)
            }
            .onAppear {
                // Adiciona os itens conforme necessário
                if !img1.isEmpty { items.append(Item(image: img1)) }
                if !img2.isEmpty { items.append(Item(image: img2)) }
                if !img3.isEmpty { items.append(Item(image: img3)) }
                if !img4.isEmpty { items.append(Item(image: img4)) }
                if !img5.isEmpty { items.append(Item(image: img5)) }
                
                print("Items: \(items)")
            }
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: colorHex(color: titleFontColor)))
                .padding()
            Text(ibody)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: colorHex(color: bodyFontColor)))
            
            HStack {
                if btnLeftText != "" {
                    if !btnLeftActionLink.isEmpty && !hasActionButtonLeft {
                        Link(destination: URL(string: btnLeftActionLink)!, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(Color(hex: colorHex(color: btnLeftBgColor)))
                                Text(btnLeftText)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: colorHex(color: btnLeftTextColor)))
                                    .padding(10)
                            }
                            .padding(5)
                        }).simultaneousGesture(TapGesture().onEnded { isActive = false })
                    } else {
                        IButton(
                            label: btnLeftText,
                            colorBg: btnLeftBgColor,
                            colorFont: btnLeftTextColor,
                            isActive: $isActive,
                            action: actionButtonLeft)
                    }
                }
                if btnRightText != "" {
                    if !btnRightActionLink.isEmpty && !hasActionButtonRight{
                        Link(destination: URL(string: btnRightActionLink)!, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .foregroundColor(Color(hex: colorHex(color: btnRightBgColor)))
                                    Text(btnRightText)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: colorHex(color: btnRightTextColor)))
                                        .padding(10)
                                }
                                .padding(5)
                        }).simultaneousGesture(TapGesture().onEnded { isActive = false })
                    }
                    else {
                        IButton(
                            label: btnRightText,
                            colorBg: btnRightBgColor,
                            colorFont: btnRightTextColor,
                            isActive: $isActive,
                            action: actionButtonRight)
                    }
                }
                
                WebImage(url: URL(string: impression))
            }
        }
    }
    
    private func colorHex(color: String) -> String {
        return color.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
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

//#Preview {
//    InAppRichContent()
//}
