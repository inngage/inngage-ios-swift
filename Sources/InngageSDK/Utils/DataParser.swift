import Foundation

func parseData(_ data: [String: Any]) -> (title: String, body: String, titleFontColor: String, bodyFontColor: String, btnLeftText: String, btnLeftTextColor: String, btnLeftBgColor: String, btnLeftActionType: String, btnLeftActionLink: String, btnRightText: String, btnRightTextColor: String, btnRightBgColor: String, btnRightActionType: String, btnRightActionLink: String, backgroundColor: String, img1: String, img2: String, img3: String, img4: String, img5: String) {
    
    var title: String = ""
    var body: String = ""
    var titleFontColor: String = ""
    var bodyFontColor: String = ""
    
    var btnLeftText: String = ""
    var btnLeftTextColor: String = ""
    var btnLeftBgColor: String = ""
    var btnLeftActionType: String = ""
    var btnLeftActionLink: String = ""
    
    var btnRightText: String = ""
    var btnRightTextColor: String = ""
    var btnRightBgColor: String = ""
    var btnRightActionType: String = ""
    var btnRightActionLink: String = ""
    
    var backgroundColor: String = ""
    
    var img1: String = ""
    var img2: String = ""
    var img3: String = ""
    var img4: String = ""
    var img5: String = ""

    if let aps = data["aps"] as? [String: Any],
       let inapp = aps["inapp"] as? [String: Any],
       let richContent = inapp["rich_content"] as? [String: Any] {
        
        title = inapp["title"] as? String ?? ""
        titleFontColor = inapp["title_font_color"] as? String ?? ""
        body = inapp["body"] as? String ?? ""
        bodyFontColor = inapp["body_font_color"] as? String ?? ""
        
        btnLeftText = inapp["btn_left_txt"] as? String ?? ""
        btnLeftTextColor = inapp["btn_left_text_color"] as? String ?? ""
        btnLeftBgColor = inapp["btn_left_bg_color"] as? String ?? ""
        btnLeftActionLink = inapp["btn_left_action_link"] as? String ?? ""
        btnLeftActionType = inapp["btn_left_action_type"] as? String ?? ""
        
        btnRightText = inapp["btn_right_txt"] as? String ?? ""
        btnRightTextColor = inapp["btn_right_text_color"] as? String ?? ""
        btnRightBgColor = inapp["btn_right_bg_color"] as? String ?? ""
        btnRightActionLink = inapp["btn_right_action_link"] as? String ?? ""
        btnRightActionType = inapp["btn_right_action_type"] as? String ?? ""
        
        backgroundColor = inapp["background_color"] as? String ?? ""
        
        img1 = richContent["img1"] as? String ?? ""
        img2 = richContent["img2"] as? String ?? ""
        img3 = richContent["img3"] as? String ?? ""
        img4 = richContent["img4"] as? String ?? ""
        img5 = richContent["img5"] as? String ?? ""
    }

    return (title, body, titleFontColor, bodyFontColor, btnLeftText, btnLeftTextColor, btnLeftBgColor, btnLeftActionType, btnLeftActionLink, btnRightText, btnRightTextColor, btnRightBgColor, btnRightActionType, btnRightActionLink, backgroundColor, img1, img2, img3, img4, img5)
}

func parseAdditionalData(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let str = userInfo["additional_data"] as? String,
          let data = str.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    return json
}
