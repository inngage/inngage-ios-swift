import Foundation

/// Estado de sessão da SDK — fonte única do `appToken`/`identifier`/`registration`
/// capturados no registro, usados por `sendEvent` (fallback) e pelo reporte de
/// abertura de notificação.
///
/// É um `actor` para garantir isolamento verificado pelo compilador (Swift 6) e
/// persiste em `UserDefaults`, de modo que o estado sobreviva ao cold start
/// (ex.: tap em push com o app previamente encerrado).
actor InngageSession {
    static let shared = InngageSession()

    private let defaults: UserDefaults

    private enum Key {
        static let appToken = "inngage.session.appToken"
        static let identifier = "inngage.session.identifier"
        static let registration = "inngage.session.registration"
        static let anonymousId = "inngage.session.anonymousId"
        static let blockDeepLink = "inngage.session.blockDeepLink"
    }

    private(set) var appToken: String
    private(set) var identifier: String
    private(set) var registration: String
    /// Quando `true`, `handleNotificationInteraction` não abre o link do push
    /// (`deep`/`inapp`). Definido pelo integrador em `registerSubscriber`.
    private(set) var blockDeepLink: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appToken = defaults.string(forKey: Key.appToken) ?? ""
        self.identifier = defaults.string(forKey: Key.identifier) ?? ""
        self.registration = defaults.string(forKey: Key.registration) ?? ""
        // `bool(forKey:)` devolve `false` quando a chave não existe — default seguro.
        self.blockDeepLink = defaults.bool(forKey: Key.blockDeepLink)
    }

    /// Atualiza e persiste o estado da sessão.
    ///
    /// `blockDeepLink` é persistido junto porque o tap em push pode ocorrer em
    /// cold start, antes de qualquer `registerSubscriber` da execução atual —
    /// mantido só em memória, o bloqueio falharia exatamente nesse cenário.
    func update(appToken: String, identifier: String, registration: String, blockDeepLink: Bool = false) {
        self.appToken = appToken
        self.identifier = identifier
        self.registration = registration
        self.blockDeepLink = blockDeepLink
        defaults.set(appToken, forKey: Key.appToken)
        defaults.set(identifier, forKey: Key.identifier)
        defaults.set(registration, forKey: Key.registration)
        defaults.set(blockDeepLink, forKey: Key.blockDeepLink)
    }

    /// Identifier anônimo estável — gerado uma única vez e persistido.
    ///
    /// Usa um `UUID` (e não `identifierForVendor`) porque o vendor id pode ser
    /// `nil` e é resetado quando o usuário remove todos os apps do vendor, o que
    /// causaria colisão/duplicidade de assinante. O `UUID` persistido é único por
    /// instalação e estável entre execuções.
    func anonymousIdentifier() -> String {
        if let id = defaults.string(forKey: Key.anonymousId), !id.isEmpty { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: Key.anonymousId)
        return id
    }

    /// Resolve o identifier: usa o valor do app quando preenchido; caso contrário,
    /// recorre ao identifier anônimo estável. Garante que o subscribe nunca vá com
    /// identifier vazio.
    func resolvedIdentifier(_ provided: String?) -> String {
        let trimmed = provided?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? anonymousIdentifier() : trimmed
    }
}
