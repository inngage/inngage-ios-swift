import Foundation
import UserNotifications

/// Utilitário para baixar e anexar imagens a notificações push
public class InngageImageHelper {
    
    public static func attachment(from userInfo: [AnyHashable: Any], completion: @escaping (UNNotificationAttachment?) -> Void) {
        guard let imageURLString = userInfo["image"] as? String,
              let imageURL = URL(string: imageURLString) else {
            completion(nil)
            return
        }

        downloadImage(from: imageURL, completion: completion)
    }

    private static func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL else {
                InngageLogger.log("❌ Erro ao baixar imagem: \(error?.localizedDescription ?? "desconhecido")")
                completion(nil)
                return
            }

            let fileManager = FileManager.default
            let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let localURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("image.\(fileExtension)")

            do {
                try? fileManager.removeItem(at: localURL)
                try fileManager.moveItem(at: tempURL, to: localURL)
                let attachment = try UNNotificationAttachment(identifier: "image", url: localURL, options: nil)
                completion(attachment)
            } catch {
                InngageLogger.log("❌ Erro ao criar attachment: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}
