import AppKit
import ApplicationServices

protocol RunningApplicationActivating {
    var processIdentifier: pid_t { get }

    @discardableResult
    func unhide() -> Bool

    @discardableResult
    func activate(options: NSApplication.ActivationOptions) -> Bool
}

extension NSRunningApplication: RunningApplicationActivating {}

protocol ApplicationWindowRaising {
    func raiseWindows(forProcessIdentifier processIdentifier: pid_t)
}

struct AccessibilityWindowRaiser: ApplicationWindowRaising {
    func raiseWindows(forProcessIdentifier processIdentifier: pid_t) {
        let app = AXUIElementCreateApplication(processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement] else {
            return
        }

        for window in windows {
            unminimize(window)
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
    }

    private func unminimize(_ window: AXUIElement) {
        var isSettable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(window, kAXMinimizedAttribute as CFString, &isSettable) == .success,
              isSettable.boolValue else {
            return
        }

        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
    }
}

enum AppActivator {
    static func activate(_ entry: AppEntry) {
        guard let app = NSRunningApplication(processIdentifier: entry.id) else { return }
        activate(app, windowRaiser: AccessibilityWindowRaiser())
    }

    static func activate(_ app: any RunningApplicationActivating,
                         windowRaiser: any ApplicationWindowRaising) {
        app.unhide()
        app.activate(options: [.activateAllWindows])
        windowRaiser.raiseWindows(forProcessIdentifier: app.processIdentifier)
    }
}
