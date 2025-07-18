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
        body: T,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.rawValue) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(body)
            urlRequest.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                InngageLogger.log("➡️ [API Request] URL: \(url.absoluteString)")
                InngageLogger.log("➡️ [API Request] Body: \(jsonString)")
            }
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                InngageLogger.log("❌ [API Error] \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                InngageLogger.log("❌ [API Error] No response data")
                completion(.failure(NSError(domain: "No response", code: 500, userInfo: nil)))
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            InngageLogger.log("✅ [API Response] Status code: \(httpResponse.statusCode)")
            InngageLogger.log("✅ [API Response] Body: \(responseString)")

            if httpResponse.statusCode == 200 {
                completion(.success(data))
            } else {
                let errorDescription = String(data: data, encoding: .utf8) ?? "Unknown error"
                let httpError = NSError(
                    domain: "HTTPError",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorDescription]
                )
                completion(.failure(httpError))
            }
        }

        task.resume()
    }

    func sendSubscriptionRequest(subscribe: Subscribe, completion: @escaping (Result<Void, Error>) -> Void) {
        let subscribeRequest = SubscribeRequest(registerSubscriberRequest: subscribe)
        sendRequest(endpoint: .subscription, body: subscribeRequest) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendEventRequest(event: Event, completion: @escaping (Result<Void, Error>) -> Void){
        let eventRequest = EventRequest(newEventRequest: event)
        sendRequest(endpoint: .event, body: eventRequest) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendNotificationRequest(notification: Notification, completion: @escaping (Result<Void, Error>) -> Void){
        let notificationRequest = NotificationRequest(notificationRequest: notification)
        sendRequest(endpoint: .notification, body: notificationRequest) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
