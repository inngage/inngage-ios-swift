import Foundation

struct SubscribeRequest: Encodable {
    let registerSubscriberRequest: Subscribe
}

struct EventRequest: Encodable {
    let newEventRequest: Event
}

struct NotificationRequest: Encodable {
    let notificationRequest: Notification
}

enum APIEndpoint: String {
    case subscription = "/v1/subscription/"
    case notification = "/v1/notification/"
    case event = "/v1/events/newEvent/"
}

class ApiManager {
    private let baseURL = "https://api.inngage.com.br"

    private func sendRequest<T: Encodable>(
        endpoint: APIEndpoint,
        method: String = "POST",
        body: T
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint.rawValue) else {
            throw InngageError.badURL
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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw InngageError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InngageError.invalidResponse(status: -1, body: nil)
        }

        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        InngageLogger.log("✅ [API Response] Status code: \(httpResponse.statusCode)")
        InngageLogger.log("✅ [API Response] Body: \(responseString)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw InngageError.invalidResponse(status: httpResponse.statusCode, body: responseString)
        }

        return data
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
