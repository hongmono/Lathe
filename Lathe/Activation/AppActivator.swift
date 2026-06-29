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

        let plan = Self.raisePlan(minimized: windows.map(isMinimized))

        if let index = plan.unminimize {
            unminimize(windows[index])
        }
        for index in plan.raise {
            AXUIElementPerformAction(windows[index], kAXRaiseAction as CFString)
        }
    }

    /// Mirrors ⌘Tab: if any window is already visible, raise only those and leave
    /// minimized windows alone. Restore a single window only when every window is
    /// minimized — the frontmost in z-order, used here as the most-recent heuristic.
    static func raisePlan(minimized: [Bool]) -> (unminimize: Int?, raise: [Int]) {
        let visible = minimized.indices.filter { !minimized[$0] }
        if !visible.isEmpty {
            return (nil, Array(visible))
        }
        guard let mostRecent = minimized.indices.first else {
            return (nil, [])
        }
        return (mostRecent, [mostRecent])
    }

    private func isMinimized(_ window: AXUIElement) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &value) == .success else {
            return false
        }
        return (value as? Bool) ?? false
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
