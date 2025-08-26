import Foundation
import UIKit

public class SubscriberService {

    private let device = UIDevice.current
    private let locale = NSLocale.current
    private let apiService: ApiManager
    
    private let sdkVersion = "1.0.3"
    
    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }
    
    public func subscribe(registration: String?) async {
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
        
        let appVersion = Self.currentAppVersion() ?? "1.0.0"
        let installedAt = Self.appInstalledDateISO8601()
        let updatedAt = Self.appUpdatedDateISO8601(appVersion: appVersion)
        
        let subscribe = await Subscribe(
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
            app_version: appVersion,
            app_installed_in: installedAt,
            app_updated_in: updatedAt,
            uuid: device.identifierForVendor?.uuidString ?? "",
            custom_field: props.customFields ?? [:],
            phone_number: props.phoneNumber ?? "",
            email: props.email ?? "",
            lat: props.latitude,
            long: props.longitude,
        )
        
        do {
            try await apiService.sendSubscriptionRequest(subscribe: subscribe)
        } catch {
            InngageLogger.log("❌ Failed to subscribe: \(error)")
        }
    }
    
    private static func currentAppVersion() -> String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    private static func appInstalledDateISO8601() -> String {
        let defaults = UserDefaults.standard
        let key = "inngage.appInstalledAt"

        if let saved = defaults.string(forKey: key) {
            return saved
        }

        let iso = iso8601Now()
        if let creation = documentsCreationDateISO8601() {
            defaults.set(creation, forKey: key)
            return creation
        } else {
            defaults.set(iso, forKey: key)
            return iso
        }
    }
    
    private static func appUpdatedDateISO8601(appVersion: String) -> String {
        let defaults = UserDefaults.standard
        let verKey = "inngage.lastSeenAppVersion"
        let updKey = "inngage.appUpdatedAt"

        let previousVersion = defaults.string(forKey: verKey)

        if previousVersion == nil {
            let installed = appInstalledDateISO8601()
            defaults.set(appVersion, forKey: verKey)
            defaults.set(installed, forKey: updKey)
            return installed
        }

        if previousVersion != appVersion {
            let now = iso8601Now()
            defaults.set(appVersion, forKey: verKey)
            defaults.set(now, forKey: updKey)
            return now
        }

        if let saved = defaults.string(forKey: updKey) {
            return saved
        } else {
            let installed = appInstalledDateISO8601()
            defaults.set(installed, forKey: updKey)
            return installed
        }
    }
    
    private static func documentsCreationDateISO8601() -> String? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        do {
            let values = try url.resourceValues(forKeys: [.creationDateKey])
            if let date = values.creationDate {
                return iso8601(date)
            }
        } catch {
            // ignore
        }
        return nil
    }

    private static func iso8601Now() -> String {
        iso8601(Date())
    }

    private static func iso8601(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: date)
    }
}
