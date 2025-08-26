import Foundation
import UIKit

final class DefaultAPIClient: APIClient {
    private let api = ApiManager()
    func postSubscription(_ payload: Subscribe) async throws {
        try await api.sendSubscriptionRequest(subscribe: payload)
    }
}

final class DefaultDeviceInfoProvider: DeviceInfoProvider {
    private let device = UIDevice.current
    private let locale = Locale.current
    var platform: String { device.systemName }
    var osVersion: String { device.systemVersion }
    var deviceModel: String { device.name }
    var deviceManufacturer: String { device.model }
    var uuid: String { device.identifierForVendor?.uuidString ?? "" }
    var osLocale: String {
        if #available(iOS 16, *) { return locale.language.languageCode?.identifier ?? "" }
        return Locale.preferredLanguages.first ?? ""
    }
    var osLanguage: String { osLocale }
}

final class DefaultAppInfoProvider: AppInfoProvider {
    var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0" }
    var installedAtISO: String { DateTracker.appInstalledDateISO8601() }
    var updatedAtISO: String { DateTracker.appUpdatedDateISO8601(appVersion: appVersion) }
}

enum DateTracker {
    static func appInstalledDateISO8601() -> String {
        let defaults = UserDefaults.standard
        let key = "inngage.appInstalledAt"
        if let saved = defaults.string(forKey: key) { return saved }
        let iso = iso8601Now()
        if let creation = documentsCreationDateISO8601() {
            defaults.set(creation, forKey: key)
            return creation
        } else {
            defaults.set(iso, forKey: key)
            return iso
        }
    }

    static func appUpdatedDateISO8601(appVersion: String) -> String {
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
        if let saved = defaults.string(forKey: updKey) { return saved }
        let installed = appInstalledDateISO8601()
        defaults.set(installed, forKey: updKey)
        return installed
    }

    private static func documentsCreationDateISO8601() -> String? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        do {
            let values = try url.resourceValues(forKeys: [.creationDateKey])
            if let date = values.creationDate { return iso8601(date) }
        } catch { }
        return nil
    }

    private static func iso8601Now() -> String { iso8601(Date()) }
    private static func iso8601(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: date)
    }
}
