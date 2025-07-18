import Foundation

public class NotificationService {
    
    private let apiService: ApiManager
    
    init(apiService: ApiManager = ApiManager()) {
        self.apiService = apiService
    }
    
    public func updateNotificationStatus(appToken: String, notId: String) {
        
        let notification = Notification(
            app_token: appToken,
            notId: notId
        )
        
        apiService.sendNotificationRequest(notification: notification) { result in
            switch result {
            case .success:
                InngageLogger.log("✅ Change status notification successful")
            case .failure(let error):
                InngageLogger.log("❌ Failed to update notification status: \(error)")
            }
        }
    }
}
