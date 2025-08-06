import Foundation

struct SubscribeRequest: Codable {
    let registerSubscriberRequest: Subscribe
}

struct EventRequest: Codable {
    let newEventRequest: Event
}

struct NotificationRequest: Codable {
    let notificationRequest: Notification
}

enum APIEndpoint: String {
    case subscription = "/v1/subscription/"
    case notification = "/v1/notification/"
    case event = "/v1/events/newEvent/"
}

public class ApiManager {
    private let baseURL = "https://api.inngage.com.br"

    private func sendRequest<T: Codable>(
        endpoint: APIEndpoint,
        method: String = "POST",
        body: T
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint.rawValue) else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONEncoder().encode(body)
        urlRequest.httpBody = jsonData

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            InngageLogger.log("➡️ [API Request] URL: \(url.absoluteString)")
            InngageLogger.log("➡️ [API Request] Body: \(jsonString)")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        InngageLogger.log("✅ [API Response] Status code: \(httpResponse.statusCode)")
        InngageLogger.log("✅ [API Response] Body: \(responseString)")

        if httpResponse.statusCode == 200 {
            return data
        } else {
            let errorDescription = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "HTTPError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorDescription]
            )
        }
    }

    func sendSubscriptionRequest(subscribe: Subscribe) async throws {
        let subscribeRequest = SubscribeRequest(registerSubscriberRequest: subscribe)
        _ = try await sendRequest(endpoint: .subscription, body: subscribeRequest)
    }
    
    func sendEventRequest(event: Event) async throws {
        let eventRequest = EventRequest(newEventRequest: event)
        _ = try await sendRequest(endpoint: .event, body: eventRequest)
    }
    
    func sendNotificationRequest(notification: Notification) async throws {
        let notificationRequest = NotificationRequest(notificationRequest: notification)
        _ = try await sendRequest(endpoint: .notification, body: notificationRequest)
    }
}
