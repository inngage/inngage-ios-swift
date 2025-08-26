import Foundation
import SafariServices
import UIKit

public class InngageSDK {
    public static let shared = InngageSDK()
    //private let subscriberService = SubscriberService()
    private let eventService = EventService()
    private let notificationService = NotificationService()
    
    private let orchestrator = SubscriberOrchestrator()
    
    private let properties = InngageProperties.shared
    
    public func registerSubscriber(
        appToken: String,
        identifier: String,
        fcmToken: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        customFields: [String: Any]? = nil,
        requestGeolocation: Bool = false
    ) async {
        let input = SubscribeInput(
            appToken: appToken,
            identifier: identifier,
            email: email,
            phone: phoneNumber,
            customFields: customFields,
            requestGeolocation: requestGeolocation,
            registrationToken: fcmToken
        )
        await orchestrator.register(input: input)
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
        ) async {
            await eventService.sendEvent(
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
    
    public func handleNotificationInteraction(data: [AnyHashable: Any]) async {
        if let notId = data["notId"] as? String {
            await notificationService.updateNotificationStatus(
                appToken: properties.appToken,
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
                if let topVC = UIApplication.shared.keyWindow?.rootViewController {
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
