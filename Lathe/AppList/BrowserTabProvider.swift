import AppKit
import ApplicationServices
import Foundation

struct BrowserTabEntry: Identifiable, Equatable {
    let id: String
    let title: String
    let windowOrdinal: Int
    let window: WindowEntry?
    let isSelected: Bool
}

@MainActor
protocol BrowserTabProviding: AnyObject {
    func tabs(forProcessIdentifier pid: pid_t, windows: [WindowEntry]) -> [BrowserTabEntry]

    @discardableResult
    func activate(tab: BrowserTabEntry) -> Bool
}

/// Reads and selects browser tabs through the Accessibility hierarchy. This keeps
/// the feature inside Lathe's existing Accessibility permission instead of adding
/// a separate per-browser Automation permission.
@MainActor
final class AccessibilityBrowserTabProvider: BrowserTabProviding {
    private static let maximumTraversalDepth = 18
    private static let maximumVisitedElementsPerWindow = 2_000

    private var tabElementsByID: [String: AXUIElement] = [:]

    func tabs(forProcessIdentifier pid: pid_t, windows: [WindowEntry]) -> [BrowserTabEntry] {
        tabElementsByID = [:]

        let axApplication = AXUIElementCreateApplication(pid)
        guard let application = NSRunningApplication(processIdentifier: pid),
              Self.supports(bundleIdentifier: application.bundleIdentifier),
              let axWindows = Self.elements(
                from: axApplication,
                attribute: kAXWindowsAttribute as CFString
              ) else {
            return []
        }

        let focusedWindow = Self.element(
            from: axApplication,
            attribute: kAXFocusedWindowAttribute as CFString
        )
        let windowsByID = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0) })
        var entries: [BrowserTabEntry] = []

        for (windowIndex, axWindow) in axWindows.enumerated() {
            let matchedWindow = Self.matchWindow(axWindow, windowsByID: windowsByID, windows: windows)
            var visitedCount = 0
            let tabElements = Self.tabElements(
                beneath: axWindow,
                depth: 0,
                visitedCount: &visitedCount
            )

            for (tabIndex, element) in tabElements.enumerated() {
                let title = Self.tabTitle(element)
                guard !title.isEmpty else { continue }

                let id = "\(pid):\(windowIndex):\(tabIndex):\(CFHash(element))"
                let entry = BrowserTabEntry(
                    id: id,
                    title: title,
                    windowOrdinal: windowIndex + 1,
                    window: matchedWindow,
                    isSelected: Self.boolValue(element, attribute: kAXSelectedAttribute as CFString)
                        && (focusedWindow == nil || CFEqual(axWindow, focusedWindow))
                )
                entries.append(entry)
                tabElementsByID[id] = element
            }
        }

        return entries
    }

    @discardableResult
    func activate(tab: BrowserTabEntry) -> Bool {
        guard let element = tabElementsByID[tab.id] else { return false }
        return AXUIElementPerformAction(element, kAXPressAction as CFString) == .success
    }

    nonisolated static func supports(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }

        let exactIdentifiers: Set<String> = [
            "at.studio.AsideBrowser",
            "com.apple.Safari",
            "company.thebrowser.Browser",
            "org.mozilla.firefox",
        ]
        if exactIdentifiers.contains(bundleIdentifier) { return true }

        return bundleIdentifier.hasPrefix("com.google.Chrome")
            || bundleIdentifier.hasPrefix("com.brave.Browser")
            || bundleIdentifier.hasPrefix("com.microsoft.edgemac")
            || bundleIdentifier.hasPrefix("com.vivaldi.Vivaldi")
    }

    private static func tabElements(beneath element: AXUIElement,
                                    depth: Int,
                                    visitedCount: inout Int) -> [AXUIElement] {
        guard depth <= maximumTraversalDepth,
              visitedCount < maximumVisitedElementsPerWindow else {
            return []
        }
        visitedCount += 1

        let role = stringValue(element, attribute: kAXRoleAttribute as CFString)
        if role == "AXWebArea" {
            // Browser content can contain arbitrary radio buttons. It is never part
            // of the browser chrome tab strip and can be large, so stop here.
            return []
        }

        let subrole = stringValue(element, attribute: kAXSubroleAttribute as CFString)
        if subrole == NSAccessibility.Subrole.tabButtonSubrole.rawValue,
           supportsPressAction(element) {
            return [element]
        }

        guard let children = elements(from: element, attribute: kAXChildrenAttribute as CFString) else {
            return []
        }
        return children.flatMap {
            tabElements(beneath: $0, depth: depth + 1, visitedCount: &visitedCount)
        }
    }

    private static func supportsPressAction(_ element: AXUIElement) -> Bool {
        var value: CFArray?
        guard AXUIElementCopyActionNames(element, &value) == .success,
              let actions = value as? [String] else {
            return false
        }
        return actions.contains(kAXPressAction as String)
    }

    private static func tabTitle(_ element: AXUIElement) -> String {
        let title = stringValue(element, attribute: kAXTitleAttribute as CFString)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        return stringValue(element, attribute: kAXDescriptionAttribute as CFString)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matchWindow(_ axWindow: AXUIElement,
                                    windowsByID: [Int: WindowEntry],
                                    windows: [WindowEntry]) -> WindowEntry? {
        if let windowID = WindowListProvider.directCGWindowID(axWindow),
           let window = windowsByID[windowID] {
            return window
        }

        let title = WindowListProvider.axTitle(axWindow)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        return windows.first { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == title }
    }

    private static func elements(from element: AXUIElement, attribute: CFString) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? [AXUIElement]
    }

    private static func element(from element: AXUIElement, attribute: CFString) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private static func stringValue(_ element: AXUIElement, attribute: CFString) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return ""
        }
        return value as? String ?? ""
    }

    private static func boolValue(_ element: AXUIElement, attribute: CFString) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return false
        }
        return value as? Bool ?? false
    }
}
