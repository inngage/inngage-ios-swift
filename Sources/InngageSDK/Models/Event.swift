import Foundation

struct Event: Encodable {
    var app_token: String
    var identifier: String
    var registration: String
    var event_name: String
    var event_values: [String: Any]?
    var conversion_event: Bool
    var conversion_value: Double
    var conversion_notid: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(app_token, forKey: .app_token)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(registration, forKey: .registration)
        try container.encode(event_name, forKey: .event_name)
        try container.encode(conversion_event, forKey: .conversion_event)
        try container.encode(conversion_value, forKey: .conversion_value)
        try container.encode(conversion_notid, forKey: .conversion_notid)
        
        if let fields = event_values {
            var custom = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .event_values)
            for (key, value) in fields {
                let codingKey = DynamicKey(stringValue: key)!
                switch value {
                case let v as String: try custom.encode(v, forKey: codingKey)
                case let v as Int:    try custom.encode(v, forKey: codingKey)
                case let v as Double: try custom.encode(v, forKey: codingKey)
                case let v as Bool:   try custom.encode(v, forKey: codingKey)
                default: break
                }
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case app_token, identifier, registration, event_name, conversion_event,
             conversion_value, conversion_notid, event_values
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
