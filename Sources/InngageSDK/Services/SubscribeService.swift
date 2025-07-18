import Foundation
import UIKit

public class SubscriberService {

    private let device = UIDevice.current
    private let locale = NSLocale.current
    private let apiService: ApiManager
    
    private let defaultAppVersion = "1.0.0"
    private let sdkVersion = "1.0.0"
    private let appInstalledDate = "2024-07-31T09:52:30.433905"
    private let appUpdatedDate = "2024-07-31T09:52:30.433905"
    
    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }
    
    public func subscribe(registration: String?) {
        let props = InngageProperties.shared
        
        let osLocale: String
        let osLanguage: String
        
        if #available(iOS 16, *) {
            osLocale = locale.language.languageCode?.identifier ?? ""
            osLanguage = locale.language.languageCode?.identifier ?? ""
        } else {
            osLocale = Locale.preferredLanguages.first ?? ""
            osLanguage = Locale.preferredLanguages.first ?? ""
        }
        
        let subscribe = Subscribe(
            app_token: props.appToken,
            identifier: props.identifier,
            registration: registration ?? "",
            platform: device.systemName,
            sdk: sdkVersion,
            device_model: device.name,
            device_manufacturer: device.model,
            os_locale: osLocale,
            os_language: osLanguage,
            os_version: device.systemVersion,
            app_version: defaultAppVersion,
            app_installed_in: appInstalledDate,
            app_updated_in: appUpdatedDate,
            uuid: device.identifierForVendor?.uuidString ?? "",
            phone_number: props.phoneNumber ?? "",
            email: props.email ?? "",
            lat: props.latitude,
            long: props.longitude,
        )
        
        apiService.sendSubscriptionRequest(subscribe: subscribe) { result in
            switch result {
            case .success:
                InngageLogger.log("✅ Subscription successful")
            case .failure(let error):
                InngageLogger.log("❌ Failed to subscribe: \(error)")
            }
        }
    }
}
