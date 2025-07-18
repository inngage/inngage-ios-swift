import SwiftUI

struct Item: Identifiable {
    private(set) var id: UUID = .init()
    var image: String
}

struct Carrousel<Content: View, Item: RandomAccessCollection>: View where Item: MutableCollection, Item.Element: Identifiable {
    
    var showPagingControl: Bool = true
    var pagingControlSpacing: CGFloat = 20
    var spacing: CGFloat = 10
    
    @Binding var data: Item
    @ViewBuilder var content: (Binding<Item.Element>) -> Content
    var body: some View {
        VStack(spacing: pagingControlSpacing){
            if #available(iOS 17.0, *) {
                let showsIndicator: ScrollIndicatorVisibility = .hidden
                
                ScrollView(.horizontal){
                    HStack(spacing: spacing){
                        ForEach($data){ item in
                            VStack(spacing: 0){
                                content(item)
                            }
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(showsIndicator)
                .scrollTargetBehavior(.viewAligned)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: spacing) {
                        ForEach($data) { item in
                            VStack(spacing: 0) {
                                content(item)
                            }
                            // Alternativa: Definir o tamanho manualmente para versões anteriores
                            .frame(minWidth: 100, maxWidth: 800) // Ajuste conforme necessário
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    InAppView()
//}
