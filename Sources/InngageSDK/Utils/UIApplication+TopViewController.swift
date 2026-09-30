import UIKit

extension UIApplication {
    /// Substitui o `keyWindow` depreciado (iOS 13+): encontra o top view controller
    /// varrendo as `connectedScenes` ativas e descendo a cadeia de apresentação.
    func topViewController() -> UIViewController? {
        let keyWindow = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
