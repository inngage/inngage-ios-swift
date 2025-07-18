class InngageProperties {
    static var shared = InngageProperties()
    
    var appToken: String = ""
    var identifier: String = ""
    var registration: String = ""
    var email: String?
    var phoneNumber: String?
    var customFields: [String: Any]?
    var latitude: String?
    var longitude: String?
}
