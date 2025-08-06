import Foundation

public class EventService {
    
    private let apiService: ApiManager
    
    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }
    
    public func sendEvent(
        appToken: String,
        identifier: String? = nil,
        registration: String? = nil,
        eventName: String,
        eventValues: [String: Any]? = nil,
        conversionEvent: Bool = false,
        conversionValue: Double = 0.0,
        conversionNotId: String? = nil
    ) async {
        let props = InngageProperties.shared
        
        let event = Event(
            app_token: appToken,
            identifier: identifier ?? props.identifier,
            registration: registration ?? props.registration,
            event_name: eventName,
            conversion_event: conversionEvent,
            conversion_value: conversionValue,
            conversion_notid: conversionNotId ?? ""
        )
        
        do {
            try await apiService.sendEventRequest(event: event)
        } catch {
            InngageLogger.log("❌ Failed to send event: \(error)")
        }
    }
}
