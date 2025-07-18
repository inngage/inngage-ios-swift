import Foundation

struct Subscribe: Codable {
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
    var custom_field: [String: String] = [:]
    var phone_number: String
    var email: String
    var lat: String?
    var long: String?
}
