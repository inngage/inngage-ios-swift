public class InngageAnalytics {
    
    public static func extractUTMEvent(from userInfo: [AnyHashable: Any]) -> (name: String, parameters: [String: Any])? {
        guard let utmSource = userInfo["inn_utm_source"] as? String, !utmSource.trimmingCharacters(in: .whitespaces).isEmpty,
              let utmMedium = userInfo["inn_utm_medium"] as? String,
              let utmTerm = userInfo["inn_utm_term"] as? String,
              let utmCampaign = userInfo["inn_utm_campaign"] as? String else {
            return nil
        }

        let parameters: [String: Any] = [
            "utm_source": utmSource,
            "utm_medium": utmMedium,
            "utm_campaign": utmCampaign,
            "utm_term": utmTerm
        ]

        return (name: "inngage_notification_click", parameters: parameters)
    }
}
