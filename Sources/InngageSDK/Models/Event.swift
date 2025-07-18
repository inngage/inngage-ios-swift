import Foundation

struct Event: Codable {
    var app_token: String
    var identifier: String
    var registration: String
    var event_name: String
    var event_values: [String: String] = [:]
    var conversion_event: Bool
    var conversion_value: Double
    var conversion_notid: String
}
