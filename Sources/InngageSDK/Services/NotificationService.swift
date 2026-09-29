import Foundation

class NotificationService {

    private let apiService: ApiManager

    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }

    func updateNotificationStatus(appToken: String, notId: String) async throws {

        let notification = Notification(
            app_token: appToken,
            notId: notId
        )

        do {
            try await apiService.sendNotificationRequest(notification: notification)
        } catch {
            InngageLogger.log("❌ Failed to update notification status: \(error)")
            throw error
        }
    }
}
