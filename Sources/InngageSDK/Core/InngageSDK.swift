public class InngageSDK {
    
    public static let shared = InngageSDK()
    
    private let subscriberService = SubscriberService()
    private let eventService = EventService()
    private let notificationService = NotificationService()
    
    private let properties = InngageProperties.shared
    
    public func subscribe(
            appToken: String,
            identifier: String,
            email: String? = nil,
            phoneNumber: String? = nil,
            customFields: [String: Any]? = nil,
            requestGeolocation: Bool = false
    ) {
        if requestGeolocation {
            let locationService = LocationService()
            locationService.requestLocation { coordinate in
                self.properties.latitude = String(format: "%.6f", coordinate.latitude)
                self.properties.longitude = String(format: "%.6f", coordinate.longitude)
                print("📍 Localização salva: \(self.properties.latitude ?? "") , \(self.properties.longitude ?? "")")
            }
        }
        
        properties.appToken = appToken
        properties.identifier = identifier
        properties.email = email
        properties.phoneNumber = phoneNumber
        properties.customFields = customFields
    }
        
    /// Registra o subscriber com o token FCM no backend
    public func registerSubscriber(token: String) {
        properties.registration = token
        subscriberService.subscribe(registration: token)
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
        ) {
            eventService.sendEvent(
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
    
    public func updateStatusNotification(data: [AnyHashable: Any]){
        if let notId = data["notId"] as? String {
            notificationService.updateNotificationStatus(
                appToken: properties.appToken,
                notId: notId
            )
        }
    }
}
