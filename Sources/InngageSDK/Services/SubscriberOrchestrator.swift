import Foundation

public struct SubscribeInput {
    let appToken: String
    let identifier: String
    let email: String?
    let phone: String?
    let customFields: [String: Any]?
    let requestGeolocation: Bool
    let registrationToken: String
}

public class SubscriberOrchestrator {
    private let api: APIClient
    private let device: DeviceInfoProvider
    private let app: AppInfoProvider
    private let sdkVersion: String
    private let locationService: LocationService?

    init(api: APIClient = DefaultAPIClient(),
         device: DeviceInfoProvider = DefaultDeviceInfoProvider(),
         app: AppInfoProvider = DefaultAppInfoProvider(),
         locationService: LocationService = LocationService(),
         sdkVersion: String = "1.0.3") {
        self.api = api
        self.device = device
        self.app = app
        self.locationService = locationService
        self.sdkVersion = sdkVersion
    }

    func register(input: SubscribeInput) async {
        do {
            var lat: String? = nil
            var long: String? = nil
            if input.requestGeolocation {
                do {
                    let coord = try await locationService?.getCurrentLocation()
                    lat = String(format: "%.6f", coord!.latitude)
                    long = String(format: "%.6f", coord!.longitude)
                    InngageLogger.log("📍 Localização: \(lat!), \(long!)")
                } catch {
                    print("❌ Erro ao obter localização: \(error.localizedDescription)")
                }
            }

            let payload = Subscribe(
                app_token: input.appToken,
                identifier: input.identifier,
                registration: input.registrationToken,
                platform: device.platform,
                sdk: sdkVersion,
                device_model: device.deviceModel,
                device_manufacturer: device.deviceManufacturer,
                os_locale: device.osLocale,
                os_language: device.osLanguage,
                os_version: device.osVersion,
                app_version: app.appVersion,
                app_installed_in: app.installedAtISO,
                app_updated_in: app.updatedAtISO,
                uuid: device.uuid,
                custom_field: input.customFields ?? [:],
                phone_number: input.phone ?? "",
                email: input.email ?? "",
                lat: lat,
                long: long
            )
            try await api.postSubscription(payload)
        } catch {
            print("❌ Erro ao obter localização: \(error.localizedDescription)")
            InngageLogger.log("❌ register failed: \(error)")
        }
    }
}
