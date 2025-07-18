import SwiftUI

public struct InngageInApp: View {
    @Binding var isShowing: Bool
    
    var data: [String: Any]?
    var actionButtonRight: () -> Void = {}
    var hasActionButtonRight: Bool = false
    var actionButtonLeft: () -> Void = {}
    var hasActionButtonLeft: Bool = false
    var onDismissed: () -> Void = {}
    
    @State private var carousel: Int = 0
    @State private var backgroundImage: String = ""
        
    public init(
        data: [String: Any],
        isShowing: Binding<Bool>,
        actionButtonRight: @escaping () -> Void = {},
        hasActionButtonRight: Bool = false,
        actionButtonLeft: @escaping () -> Void = {},
        hasActionButtonLeft: Bool = false,
        onDismissed: @escaping () -> Void = {}) {
            self.data = data
            self.actionButtonRight = actionButtonRight
            self.actionButtonLeft = actionButtonLeft
            self.hasActionButtonLeft = hasActionButtonLeft
            self.hasActionButtonRight = hasActionButtonRight
            self.onDismissed = onDismissed
            
            if let additionalData = parseAdditionalData(from: data),
               let richContent = additionalData["rich_content"] as? [String: Any] {
                self._backgroundImage = State(initialValue: additionalData["background_image"] as? String ?? "")
                self._carousel = State(initialValue: richContent["carousel"] as? Int ?? 0)
            }
            
            self._isShowing = isShowing
    }
    
    public var body: some View {
        Group {
            if isShowing {
                contentView()
            }
        }
        .onDisappear {
            if !isShowing {
                onDismissed()
            }
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if carousel == 1 {
            InAppRichContent(
                data: data ?? ["": ""],
                isActive: $isShowing,
                actionButtonLeft: actionButtonLeft,
                hasActionButtonLeft: hasActionButtonLeft,
                actionButtonRight: actionButtonRight,
                hasActionButtonRight: hasActionButtonRight
            )
        } else if !backgroundImage.isEmpty && carousel == 0 {
            InAppBackgroundImage(
                data: data ?? ["": ""],
                isActive: $isShowing,
                actionButtonLeft: actionButtonLeft,
                actionButtonRight: actionButtonRight
            )
        } else {
            InAppNormal(
                data: data ?? ["": ""],
                isActive: $isShowing,
                actionButtonLeft: actionButtonLeft,
                actionButtonRight: actionButtonRight
            )
        }
    }
    
    private func handleDeepLink(){
        print("Está utilizando deep link")
    }
}

//#Preview {
//    InAppView()
//}
