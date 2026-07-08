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

protocol SpecificWindowRaising {
    /// 선택한 창을 전면화한다. 앱 단위 활성화 없이 단일 창만 끌어올리는 데 성공하면 `true`.
    /// `false`면 호출부가 앱을 활성화해 마무리해야 한다.
    @discardableResult
    func raiseWindow(_ windowID: Int, forProcessIdentifier processIdentifier: pid_t) -> Bool
}

struct AccessibilityWindowRaiser: ApplicationWindowRaising, SpecificWindowRaising {
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

    @discardableResult
    func raiseWindow(_ windowID: Int, forProcessIdentifier processIdentifier: pid_t) -> Bool {
        guard let axWindow = WindowListProvider.axWindow(forProcessIdentifier: processIdentifier, cgWindowID: windowID) else {
            raiseWindows(forProcessIdentifier: processIdentifier)
            return false
        }

        unminimize(axWindow)

        // 1순위: SkyLight로 선택한 창만 전면화(형제 창은 그대로 둔다).
        if SingleWindowFocuser.focus(windowID: CGWindowID(windowID),
                                     processIdentifier: processIdentifier,
                                     axWindow: axWindow) {
            return true
        }

        // 폴백(공개 API): 선택 창을 main으로 지정 후 raise. 앱 활성화는 호출부에서 수행.
        AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        return false
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
    static func activate(_ entry: AppEntry, window: WindowEntry? = nil) {
        guard let app = NSRunningApplication(processIdentifier: entry.id) else { return }
        activate(app, window: window, windowRaiser: AccessibilityWindowRaiser())
    }

    static func activate(_ app: any RunningApplicationActivating,
                         window: WindowEntry? = nil,
                         windowRaiser: any ApplicationWindowRaising & SpecificWindowRaising) {
        app.unhide()
        if let window {
            let focused = windowRaiser.raiseWindow(window.id, forProcessIdentifier: app.processIdentifier)
            if !focused {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        } else {
            app.activate(options: [.activateAllWindows])
            windowRaiser.raiseWindows(forProcessIdentifier: app.processIdentifier)
        }
    }
}
