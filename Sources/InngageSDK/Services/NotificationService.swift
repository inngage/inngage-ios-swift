import Foundation

public class NotificationService {
    
    private let apiService: ApiManager
    
    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }
    
    public func updateNotificationStatus(appToken: String, notId: String) async {
        
        let notification = Notification(
            app_token: appToken,
            notId: notId
        )
        
        do {
            try await apiService.sendNotificationRequest(notification: notification)
        } catch {
            InngageLogger.log("❌ Failed to update notification status: \(error)")
        }
    }
}
