import ApplicationServices

enum AccessibilityChecker {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestTrust() -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let opts: CFDictionary = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}
