import ApplicationServices
import CoreGraphics
import Foundation

enum WindowVisibilityFilter {
    static let minWidth: Double = 200
    static let minHeight: Double = 80
    static let minArea: Double = 100

    static func passesOnScreenCGWindow(_ window: [String: Any]) -> Bool {
        guard passesBaseCGWindow(window) else { return false }
        guard isOnScreen(window) else { return false }
        return passesSizeThresholds(window)
    }

    static func passesBaseCGWindow(_ window: [String: Any]) -> Bool {
        let layerKey = kCGWindowLayer as String
        guard let layer = (window[layerKey] as? NSNumber)?.intValue, layer == 0 else {
            return false
        }
        guard alpha(from: window) > 0 else { return false }
        let area = boundsArea(from: window)
        guard area >= minArea else { return false }
        return true
    }

    static func passesSizeThresholds(_ window: [String: Any]) -> Bool {
        let (width, height) = boundsSize(from: window)
        return width >= minWidth && height >= minHeight
    }

    static func isOnScreen(_ window: [String: Any]) -> Bool {
        (window[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ?? false
    }

    static func alpha(from window: [String: Any]) -> Double {
        (window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1
    }

    static func boundsSize(from window: [String: Any]) -> (Double, Double) {
        let bounds = window[kCGWindowBounds as String] as? [String: Any]
        let width = (bounds?["Width"] as? NSNumber)?.doubleValue ?? 0
        let height = (bounds?["Height"] as? NSNumber)?.doubleValue ?? 0
        return (width, height)
    }

    static func boundsArea(from window: [String: Any]) -> Double {
        let (width, height) = boundsSize(from: window)
        return width * height
    }

    static func isUserFacingAXWindow(_ window: AXUIElement) -> Bool {
        let role = axString(window, kAXRoleAttribute as CFString)
        guard role == kAXWindowRole as String else { return false }

        let subrole = axString(window, kAXSubroleAttribute as CFString)
        guard !subrole.isEmpty else { return true }

        return allowedAXSubroles.contains(subrole)
    }

    private static let allowedAXSubroles: Set<String> = [
        kAXStandardWindowSubrole as String,
        kAXDialogSubrole as String,
        "AXDocumentWindow",
    ]

    private static func axString(_ element: AXUIElement, _ attribute: CFString) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let string = value as? String else {
            return ""
        }
        return string
    }
}
