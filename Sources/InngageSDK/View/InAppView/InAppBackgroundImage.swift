import SwiftUI
import SDWebImageSwiftUI

struct InAppBackgroundImage: View {
    @Binding var isActive: Bool
    var data: [String: Any]?

    var actionButtonRight: () -> Void = {}
    var actionButtonLeft: () -> Void = {}
    
    @State private var offsetY: CGFloat = UIScreen.main.bounds.height * 0.1
    @State private var blurRadius: CGFloat = 20
    
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
    @State private var backgroundImage: String = ""
    @State private var impression: String = ""
    
    @State private var onLoadBackgroundImage: Bool = false
    @State private var imageAspectRatio: CGFloat = 1.0
    @State private var imageHeight: CGFloat? = nil
    @State private var imageWidth: CGFloat? = nil

    init(
        data: [String: Any],
        isActive: Binding<Bool>,
        actionButtonLeft: @escaping () -> Void = {},
        actionButtonRight: @escaping () -> Void = {}) {
            self.actionButtonLeft = actionButtonLeft
            self.actionButtonRight = actionButtonRight
            
            self._isActive = isActive
            self.data = data
            
            if let inapp = parseAdditionalData(from: data) {
                self._title = State(initialValue: inapp["title"] as? String ?? "")
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
                self._backgroundImage = State(initialValue: inapp["background_image"] as? String ?? "")
                self._impression = State(initialValue: inapp["inpression"] as? String ?? "")
        }
    }

    var body: some View {
        ZStack {
            if onLoadBackgroundImage {
                backgroundOverlay
            }
            content
                .frame(minWidth: UIScreen.main.bounds.width * 0.8)
                .frame(height: calculateContentHeight())
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(WebImage(url: URL(string: backgroundImage))
                    .onSuccess { image, _, _  in
                        let height = image.size.height
                        let width = image.size.width
                        
                        withAnimation {
                            DispatchQueue.main.async {
                                imageAspectRatio = width / height
                                self.imageHeight = height
                                self.imageWidth = width
                                onLoadBackgroundImage = true
                                open()
                            }
                        }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFill())
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(closeButtonOverlay)
                .shadow(radius: 20)
                .padding(20)
                .offset(y: offsetY)
                .blur(radius: blurRadius)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.15), value: offsetY)
                .onAppear(perform: {
                    if onLoadBackgroundImage {
                        open()
                    }
                })
        }
    }
    
    private func calculateContentHeight() -> CGFloat {
        let contentWidth = UIScreen.main.bounds.width * 0.8
        return contentWidth / imageAspectRatio
    }

    private var backgroundOverlay: some View {
        Color.black.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                withAnimation {
                    onLoadBackgroundImage = false
                    close()
                }
            }
    }

    private var content: some View {
        VStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: colorHex(color: titleFontColor)))
                .padding()

            Text(ibody)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: colorHex(color: bodyFontColor)))

            HStack {
                if btnLeftText != "" {
                    if !btnLeftActionLink.isEmpty {
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
                    if !btnRightActionLink.isEmpty {
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
            }
            
            WebImage(url: URL(string: impression))
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
                    withAnimation {
                        onLoadBackgroundImage = false
                        close()
                    }
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

//#Preview {
//    InAppBackgroundImage()
//}
