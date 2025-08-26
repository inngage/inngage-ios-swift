import Foundation

struct Subscribe: Encodable {
    var app_token: String
    var identifier: String
    var registration: String
    var platform: String
    var sdk: String
    var device_model: String
    var device_manufacturer: String
    var os_locale: String
    var os_language: String
    var os_version: String
    var app_version: String
    var app_installed_in: String
    var app_updated_in: String
    var uuid: String
    var custom_field: [String: Any]?
    var phone_number: String
    var email: String
    var lat: String?
    var long: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(app_token, forKey: .app_token)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(registration, forKey: .registration)
        try container.encode(platform, forKey: .platform)
        try container.encode(sdk, forKey: .sdk)
        try container.encode(device_model, forKey: .device_model)
        try container.encode(device_manufacturer, forKey: .device_manufacturer)
        try container.encode(os_locale, forKey: .os_locale)
        try container.encode(os_language, forKey: .os_language)
        try container.encode(os_version, forKey: .os_version)
        try container.encode(app_version, forKey: .app_version)
        try container.encode(app_installed_in, forKey: .app_installed_in)
        try container.encode(app_updated_in, forKey: .app_updated_in)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(phone_number, forKey: .phone_number)
        try container.encode(email, forKey: .email)
        try container.encode(lat, forKey: .lat)
        try container.encode(long, forKey: .long)
        
        if let fields = custom_field {
            var custom = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .custom_field)
            for (key, value) in fields {
                let codingKey = DynamicKey(stringValue: key)!
                switch value {
                case let v as String:
                    try custom.encode(v, forKey: codingKey)
                case let v as Int:
                    try custom.encode(v, forKey: codingKey)
                case let v as Double:
                    try custom.encode(v, forKey: codingKey)
                case let v as Bool:
                    try custom.encode(v, forKey: codingKey)
                case let v as [Any]:
                    var unkeyed = custom.nestedUnkeyedContainer(forKey: codingKey)
                    for item in v {
                        switch item {
                        case let s as String: try unkeyed.encode(s)
                        case let i as Int:    try unkeyed.encode(i)
                        case let d as Double: try unkeyed.encode(d)
                        case let b as Bool:   try unkeyed.encode(b)
                        default: break
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case app_token, identifier, registration, platform, sdk,
             device_model, device_manufacturer, os_locale, os_language,
             os_version, app_version, app_installed_in, app_updated_in,
             uuid, custom_field, phone_number, email, lat, long
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
