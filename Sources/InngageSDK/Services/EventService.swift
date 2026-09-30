import Foundation

class EventService {

    private let apiService: ApiManager

    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }

    func sendEvent(
        appToken: String,
        identifier: String? = nil,
        registration: String? = nil,
        eventName: String,
        eventValues: [String: Any]? = nil,
        conversionEvent: Bool = false,
        conversionValue: Double = 0.0,
        conversionNotId: String? = nil
    ) async throws {
        let session = InngageSession.shared
        // Fallback para o estado de sessão quando o integrador não informa
        // identifier/registration; se nem a sessão os tem, usa o identifier anônimo.
        let sessionIdentifier = await session.identifier
        let sessionRegistration = await session.registration
        let resolvedIdentifier = await session.resolvedIdentifier(identifier ?? sessionIdentifier)
        let resolvedRegistration = registration ?? sessionRegistration

        let event = Event(
            app_token: appToken,
            identifier: resolvedIdentifier,
            registration: resolvedRegistration,
            event_name: eventName,
            event_values: eventValues,
            conversion_event: conversionEvent,
            conversion_value: conversionValue,
            conversion_notid: conversionNotId ?? ""
        )

        do {
            try await apiService.sendEventRequest(event: event)
        } catch {
            InngageLogger.log("❌ Failed to send event: \(error)")
            throw error
        }
    }
}
