import Foundation
import SafariServices
import UIKit

public class InngageSDK {
    public static let shared = InngageSDK()

    private let eventService = EventService()
    private let notificationService = NotificationService()

    private let orchestrator = SubscriberOrchestrator()

    private let session = InngageSession.shared

    public func registerSubscriber(
        appToken: String,
        identifier: String? = nil,
        fcmToken: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        customFields: [String: Any]? = nil,
        requestGeolocation: Bool = false,
        blockDeepLink: Bool = false
    ) async throws {
        // O identifier é opcional para o integrador, mas a API de subscription
        // exige um valor: se não vier preenchido, cai no identifier anônimo estável.
        let identifier = await session.resolvedIdentifier(identifier)

        // Fonte única do estado da sessão — usada por sendEvent (fallback) e
        // handleNotificationInteraction (reporte de abertura e bloqueio de link).
        // Persistida para sobreviver ao cold start. `blockDeepLink` é sempre
        // gravado: um subscribe posterior com `false` reverte o bloqueio.
        await session.update(
            appToken: appToken,
            identifier: identifier,
            registration: fcmToken,
            blockDeepLink: blockDeepLink
        )

        let input = SubscribeInput(
            appToken: appToken,
            identifier: identifier,
            email: email,
            phone: phoneNumber,
            customFields: customFields,
            requestGeolocation: requestGeolocation,
            registrationToken: fcmToken
        )
        try await orchestrator.register(input: input)
    }

    public func sendEvent(
            eventName: String,
            appToken: String,
            identifier: String? = nil,
            registration: String? = nil,
            eventValues: [String: Any]? = nil,
            conversionEvent: Bool = false,
            conversionValue: Double = 0.0,
            conversionNotId: String? = nil
        ) async throws {
            try await eventService.sendEvent(
                appToken: appToken,
                identifier: identifier,
                registration: registration,
                eventName: eventName,
                eventValues: eventValues,
                conversionEvent: conversionEvent,
                conversionValue: conversionValue,
                conversionNotId: conversionNotId
            )
        }

    public func handleNotificationInteraction(data: [AnyHashable: Any]) async throws {
        if let notId = data["notId"] as? String {
            try await notificationService.updateNotificationStatus(
                appToken: await session.appToken,
                notId: notId
            )
        }

        // A decisão (inclusive o bloqueio via `blockDeepLink`) é tomada fora da
        // main thread e sem UIKit; aqui só se executa a ação resolvida.
        let action = NotificationLinkResolver.resolve(
            type: data["type"] as? String,
            urlString: data["url"] as? String,
            blockDeepLink: await session.blockDeepLink
        )

        DispatchQueue.main.async {
            switch action {
            case .openExternal(let url):
                UIApplication.shared.open(url, options: [:], completionHandler: nil)

            case .openInApp(let url):
                if let topVC = UIApplication.shared.topViewController() {
                    let safariVC = SFSafariViewController(url: url)
                    safariVC.modalPresentationStyle = .formSheet
                    topVC.present(safariVC, animated: true, completion: nil)
                }

            case .blocked:
                InngageLogger.log("🔒 Tratamento de link bloqueado (blockDeepLink = true)")

            case .none:
                InngageLogger.log("🔕 Sem URL ou tipo inválido no push")
            }
        }
    }
}
