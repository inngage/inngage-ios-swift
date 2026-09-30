import Foundation

/// Ação a executar para o link de um push tocado.
enum NotificationLinkAction: Equatable {
    /// `type == "deep"`: abrir no browser / app dono do scheme (`UIApplication.open`).
    case openExternal(URL)
    /// `type == "inapp"`: abrir na webview interna (`SFSafariViewController`).
    case openInApp(URL)
    /// O integrador desligou o tratamento de link (`blockDeepLink: true`).
    case blocked
    /// Sem URL/tipo válidos ou tipo desconhecido — nada a abrir.
    case none
}

/// Decide o roteamento do link do push.
///
/// Função pura, sem UIKit, para que a regra de bloqueio seja testável sem
/// apresentar view controllers. A fachada (`InngageSDK`) só executa a ação.
enum NotificationLinkResolver {
    static func resolve(type: String?, urlString: String?, blockDeepLink: Bool) -> NotificationLinkAction {
        guard let type, let urlString, let url = URL(string: urlString) else { return .none }

        switch type {
        case "deep", "inapp":
            // O bloqueio vem antes do roteamento: com a flag ligada, nenhum dos
            // dois tipos abre nada.
            if blockDeepLink { return .blocked }
            return type == "deep" ? .openExternal(url) : .openInApp(url)

        default:
            return .none
        }
    }
}
