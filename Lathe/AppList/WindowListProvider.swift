import ApplicationServices
import CoreGraphics
import Foundation

protocol WindowListing {
    func windows(forProcessIdentifier pid: pid_t) -> [WindowEntry]
}

struct WindowListProvider: WindowListing {

    struct AXWindowMetadata: Equatable {
        let title: String
        let pathSummary: String?
        let isMinimized: Bool
    }

    struct WindowMatch: Equatable {
        let axWindow: AXUIElement
        let cgWindowID: Int
        let metadata: AXWindowMetadata
    }

    func windows(forProcessIdentifier pid: pid_t) -> [WindowEntry] {
        let onScreenCG = Self.onScreenCGWindows(forProcessIdentifier: pid)
        var onScreenPool = Dictionary(uniqueKeysWithValues: onScreenCG.map { ($0.id, $0) })
        let allLayerZero = Self.allLayerZeroCGWindows(forProcessIdentifier: pid)
        var offScreenPool = Dictionary(
            uniqueKeysWithValues: allLayerZero.filter { !onScreenPool.keys.contains($0.id) }.map { ($0.id, $0) }
        )
        let cgTitleByID = Dictionary(uniqueKeysWithValues: allLayerZero.map { ($0.id, $0.title) })

        guard let axWindows = Self.axWindows(forProcessIdentifier: pid) else {
            return onScreenCG.compactMap { cgWindow in
                let title = cgWindow.title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return nil }
                return WindowEntry(id: cgWindow.id, title: title, pathSummary: nil, isMinimized: false)
            }
        }

        return Self.matchWindows(
            axWindows: axWindows,
            onScreenPool: &onScreenPool,
            offScreenPool: &offScreenPool
        ).compactMap { match in
            let entry = WindowEntry(
                id: match.cgWindowID,
                title: Self.preferredTitle(axTitle: match.metadata.title, cgTitle: cgTitleByID[match.cgWindowID] ?? ""),
                pathSummary: match.metadata.pathSummary,
                isMinimized: match.metadata.isMinimized
            )
            return entry.isDisplayable ? entry : nil
        }
    }

    static func matchWindows(axWindows: [AXUIElement],
                             onScreenPool: inout [Int: CGWindowSnapshot],
                             offScreenPool: inout [Int: CGWindowSnapshot]) -> [WindowMatch] {
        var matches: [WindowMatch] = []

        for axWindow in axWindows {
            guard WindowVisibilityFilter.isUserFacingAXWindow(axWindow) else { continue }
            let metadata = metadata(for: axWindow)
            let cgID: Int?
            if metadata.isMinimized {
                cgID = matchUniqueToCGWindow(axWindow, pool: &offScreenPool)
                    ?? matchUniqueToCGWindow(axWindow, pool: &onScreenPool)
            } else {
                cgID = matchUniqueToCGWindow(axWindow, pool: &onScreenPool)
            }
            guard let cgID else { continue }
            matches.append(WindowMatch(axWindow: axWindow, cgWindowID: cgID, metadata: metadata))
        }

        return matches
    }

    static func preferredTitle(axTitle: String?, cgTitle: String) -> String {
        let ax = axTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cg = cgTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ax.isEmpty { return ax }
        return cg
    }

    static func axWindows(forProcessIdentifier pid: pid_t) -> [AXUIElement]? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let axWindows = value as? [AXUIElement] else {
            return nil
        }
        return axWindows
    }

    static func metadata(for axWindow: AXUIElement) -> AXWindowMetadata {
        AXWindowMetadata(
            title: axTitle(axWindow),
            pathSummary: pathSummary(for: axWindow),
            isMinimized: isMinimized(axWindow)
        )
    }

    static func pathSummary(for axWindow: AXUIElement) -> String? {
        if let document = copyAttribute(axWindow, kAXDocumentAttribute as CFString),
           let url = WindowPathSummary.url(fromDocumentValue: document),
           let summary = WindowPathSummary.summarize(url) {
            return summary
        }
        if let urlValue = copyAttribute(axWindow, kAXURLAttribute as CFString),
           let url = WindowPathSummary.url(fromDocumentValue: urlValue),
           let summary = WindowPathSummary.summarize(url) {
            return summary
        }
        return nil
    }

    static func matchUniqueToCGWindow(_ axWindow: AXUIElement,
                                        pool: inout [Int: CGWindowSnapshot]) -> Int? {
        guard !pool.isEmpty else { return nil }

        if let directID = directCGWindowID(axWindow), pool[directID] != nil {
            pool.removeValue(forKey: directID)
            return directID
        }

        let title = axTitle(axWindow)
        if !title.isEmpty,
           let id = pool.first(where: { $0.value.title == title })?.key {
            pool.removeValue(forKey: id)
            return id
        }

        if let position = axPosition(axWindow), let size = axSize(axWindow) {
            if let id = pool.first(where: { (_, snapshot) in
                guard let cgFrame = cgFrame(forWindowID: snapshot.id) else { return false }
                return framesMatch(axPosition: position, axSize: size, cgFrame: cgFrame)
            })?.key {
                pool.removeValue(forKey: id)
                return id
            }
        }

        return nil
    }

    static func axWindow(forProcessIdentifier pid: pid_t, cgWindowID: Int) -> AXUIElement? {
        let onScreenCG = onScreenCGWindows(forProcessIdentifier: pid)
        var onScreenPool = Dictionary(uniqueKeysWithValues: onScreenCG.map { ($0.id, $0) })
        let allLayerZero = allLayerZeroCGWindows(forProcessIdentifier: pid)
        var offScreenPool = Dictionary(
            uniqueKeysWithValues: allLayerZero.filter { !onScreenPool.keys.contains($0.id) }.map { ($0.id, $0) }
        )
        guard let axWindows = axWindows(forProcessIdentifier: pid) else { return nil }

        for match in matchWindows(axWindows: axWindows, onScreenPool: &onScreenPool, offScreenPool: &offScreenPool) {
            if match.cgWindowID == cgWindowID {
                return match.axWindow
            }
        }
        return nil
    }

    // MARK: - CGWindow

    struct CGWindowSnapshot: Equatable {
        let id: Int
        let title: String
        let layer: Int
        let boundsArea: Double
        let isOnScreen: Bool
    }

    static func onScreenCGWindows(forProcessIdentifier pid: pid_t) -> [CGWindowSnapshot] {
        guard let raw = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }
        return cgWindows(fromWindowList: raw, processIdentifier: pid, onScreenOnly: true)
    }

    static func allLayerZeroCGWindows(forProcessIdentifier pid: pid_t) -> [CGWindowSnapshot] {
        guard let raw = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return cgWindows(fromWindowList: raw, processIdentifier: pid, onScreenOnly: false)
    }

    static func cgWindows(fromWindowList windows: [[String: Any]],
                          processIdentifier pid: pid_t,
                          onScreenOnly: Bool = true) -> [CGWindowSnapshot] {
        let ownerPIDKey = kCGWindowOwnerPID as String
        let layerKey = kCGWindowLayer as String
        let numberKey = kCGWindowNumber as String
        let nameKey = kCGWindowName as String

        return windows.compactMap { window -> CGWindowSnapshot? in
            guard let ownerPID = (window[ownerPIDKey] as? NSNumber)?.int32Value,
                  pid_t(ownerPID) == pid else {
                return nil
            }
            guard onScreenOnly ? WindowVisibilityFilter.passesOnScreenCGWindow(window) : WindowVisibilityFilter.passesBaseCGWindow(window) else {
                return nil
            }
            guard let layer = (window[layerKey] as? NSNumber)?.intValue else { return nil }
            guard let number = (window[numberKey] as? NSNumber)?.intValue else { return nil }
            let title = window[nameKey] as? String ?? ""
            return CGWindowSnapshot(
                id: number,
                title: title,
                layer: layer,
                boundsArea: WindowVisibilityFilter.boundsArea(from: window),
                isOnScreen: WindowVisibilityFilter.isOnScreen(window)
            )
        }
    }

    static func isMinimized(_ window: AXUIElement) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &value) == .success,
              let minimized = value as? Bool else {
            return false
        }
        return minimized
    }

    static func focusedWindowID(forProcessIdentifier pid: pid_t) -> Int? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let axWindow = value else {
            return nil
        }

        let onScreenCG = onScreenCGWindows(forProcessIdentifier: pid)
        var onScreenPool = Dictionary(uniqueKeysWithValues: onScreenCG.map { ($0.id, $0) })
        let allLayerZero = allLayerZeroCGWindows(forProcessIdentifier: pid)
        var offScreenPool = Dictionary(
            uniqueKeysWithValues: allLayerZero.filter { !onScreenPool.keys.contains($0.id) }.map { ($0.id, $0) }
        )

        if isMinimized(axWindow as! AXUIElement) {
            return matchUniqueToCGWindow(axWindow as! AXUIElement, pool: &offScreenPool)
                ?? matchUniqueToCGWindow(axWindow as! AXUIElement, pool: &onScreenPool)
        }
        return matchUniqueToCGWindow(axWindow as! AXUIElement, pool: &onScreenPool)
    }

    // MARK: - AX helpers

    private static func copyAttribute(_ element: AXUIElement, _ attribute: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value
    }

    static func axTitle(_ window: AXUIElement) -> String {
        copyAttribute(window, kAXTitleAttribute as CFString) as? String ?? ""
    }

    /// `_AXUIElementGetWindow`로 AX 윈도우에서 CG 윈도우 번호를 직접 얻는다.
    /// 비공개 심볼이라 런타임에 조회하고, 없거나 실패하면 `nil`을 돌려 제목/프레임 매칭으로 폴백한다.
    private typealias AXGetWindowFunction = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> AXError

    private static let axGetWindowFunction: AXGetWindowFunction? = {
        guard let handle = dlopen(nil, RTLD_NOW) else { return nil }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "_AXUIElementGetWindow") else { return nil }
        return unsafeBitCast(symbol, to: AXGetWindowFunction.self)
    }()

    static func directCGWindowID(_ axWindow: AXUIElement) -> Int? {
        guard let function = axGetWindowFunction else { return nil }
        var windowID = CGWindowID(0)
        guard function(axWindow, &windowID) == .success, windowID != 0 else { return nil }
        return Int(windowID)
    }

    private static func axPosition(_ window: AXUIElement) -> CGPoint? {
        guard let axValue = copyAttribute(window, kAXPositionAttribute as CFString) else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    private static func axSize(_ window: AXUIElement) -> CGSize? {
        guard let axValue = copyAttribute(window, kAXSizeAttribute as CFString) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    private static func cgFrame(forWindowID windowID: Int) -> CGRect? {
        guard let raw = CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(windowID)) as? [[String: Any]],
              let window = raw.first,
              let bounds = window[kCGWindowBounds as String] as? [String: Any],
              let x = (bounds["X"] as? NSNumber)?.doubleValue,
              let y = (bounds["Y"] as? NSNumber)?.doubleValue,
              let width = (bounds["Width"] as? NSNumber)?.doubleValue,
              let height = (bounds["Height"] as? NSNumber)?.doubleValue else {
            return nil
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    static func framesMatch(axPosition: CGPoint, axSize: CGSize, cgFrame: CGRect) -> Bool {
        let tolerance: CGFloat = 2
        return abs(axPosition.x - cgFrame.origin.x) <= tolerance
            && abs(axPosition.y - cgFrame.origin.y) <= tolerance
            && abs(axSize.width - cgFrame.width) <= tolerance
            && abs(axSize.height - cgFrame.height) <= tolerance
    }
}

extension WindowListProvider.WindowMatch {
    static func == (lhs: WindowListProvider.WindowMatch, rhs: WindowListProvider.WindowMatch) -> Bool {
        lhs.cgWindowID == rhs.cgWindowID && lhs.metadata == rhs.metadata
    }
}
