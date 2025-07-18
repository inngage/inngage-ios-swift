public enum InngageLogger {

    public static var isLoggingEnabled: Bool = false

    public static func log(_ message: String) {
        guard isLoggingEnabled else { return }
        print("📘 [InngageSDK] \(message)")
    }
}
