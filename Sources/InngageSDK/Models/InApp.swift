import Foundation

struct InApp: Codable {
    var title: String
    var body: String
    var titleFontColor: String
    var bodyFontColor: String
    var buttonLeftBackgroundColor: String
    var buttonLeftTextColor: String
    var buttonLeftText: String
    var buttonLeftActionType: String
    var buttonLeftActionLink: String
    var buttonRightBackgroundColor: String
    var buttonRightTextColor: String
    var buttonRightText: String
    var buttonRightActionType: String
    var buttonRightActionLink: String
    var backgroundImage: String
    var backgroundImageActionType: String
    var backgroundImageActionLink: String
    var backgroundColor: String
    var impression: String
    var inAppMessage: Bool
    var dotColor: String
    var richContent: RichContent
}
