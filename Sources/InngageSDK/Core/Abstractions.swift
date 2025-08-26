import Foundation
import UIKit

protocol APIClient {
    func postSubscription(_ payload: Subscribe) async throws
}

protocol AppInfoProvider {
    var appVersion: String { get }
    var installedAtISO: String { get }
    var updatedAtISO: String { get }
}

protocol DeviceInfoProvider {
    var platform: String { get }
    var osVersion: String { get }
    var deviceModel: String { get }
    var deviceManufacturer: String { get }
    var uuid: String { get }
    var osLocale: String { get }
    var osLanguage: String { get }
}

protocol PayloadStore {
    func savePendingSubscribe(_ payload: Subscribe) throws
    func loadPendingSubscribe() throws -> Subscribe?
    func clearPendingSubscribe() throws
}
