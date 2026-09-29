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
        requestGeolocation: Bool = false
    ) async throws {
        // O identifier é opcional para o integrador, mas a API de subscription
        // exige um valor: se não vier preenchido, cai no identifier anônimo estável.
        let identifier = await session.resolvedIdentifier(identifier)

        // Fonte única do estado da sessão — usada por sendEvent (fallback) e
        // handleNotificationInteraction (reporte de abertura). Persistida para
        // sobreviver ao cold start.
        await session.update(appToken: appToken, identifier: identifier, registration: fcmToken)

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

        guard
            let type = data["type"] as? String,
            let urlString = data["url"] as? String,
            let url = URL(string: urlString)
        else {
            InngageLogger.log("🔕 Sem URL ou tipo inválido no push")
            return
        }

        DispatchQueue.main.async {
            switch type {
            case "deep":
                UIApplication.shared.open(url, options: [:], completionHandler: nil)

            case "inapp":
                if let topVC = UIApplication.shared.topViewController() {
                    let safariVC = SFSafariViewController(url: url)
                    safariVC.modalPresentationStyle = .formSheet
                    topVC.present(safariVC, animated: true, completion: nil)
                }

            default:
                InngageLogger.log("⚠️ Tipo de navegação desconhecido: \(type)")
            }
        }
    }
}
