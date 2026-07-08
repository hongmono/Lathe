import CoreGraphics
import XCTest
@testable import Lathe

final class WindowListProviderTests: XCTestCase {

    private func windowDict(pid: Int32,
                            number: Int,
                            name: String,
                            width: Double,
                            height: Double,
                            onScreen: Bool,
                            layer: Int = 0,
                            alpha: Double = 1) -> [String: Any] {
        [
            kCGWindowOwnerPID as String: NSNumber(value: pid),
            kCGWindowLayer as String: NSNumber(value: layer),
            kCGWindowNumber as String: NSNumber(value: number),
            kCGWindowName as String: name,
            kCGWindowIsOnscreen as String: NSNumber(value: onScreen),
            kCGWindowAlpha as String: NSNumber(value: alpha),
            kCGWindowBounds as String: ["Width": width, "Height": height],
        ]
    }

    func test_cgWindowsFiltersByProcessLayerMinimumSizeAndOnScreen() {
        let windows: [[String: Any]] = [
            windowDict(pid: 42, number: 100, name: "Editor", width: 800, height: 600, onScreen: true),
            windowDict(pid: 42, number: 101, name: "Menu", width: 800, height: 600, onScreen: true, layer: 8),
            windowDict(pid: 99, number: 102, name: "Other", width: 800, height: 600, onScreen: true),
            windowDict(pid: 42, number: 103, name: "Tiny", width: 5, height: 5, onScreen: true),
            windowDict(pid: 42, number: 104, name: "", width: 2560, height: 30, onScreen: false),
            windowDict(pid: 42, number: 105, name: "", width: 2560, height: 30, onScreen: true),
        ]

        let result = WindowListProvider.cgWindows(fromWindowList: windows, processIdentifier: 42, onScreenOnly: true)
        XCTAssertEqual(result.map(\.id), [100])
        XCTAssertEqual(result.first?.title, "Editor")
    }

    func test_cgWindowsIncludesOffScreenWhenNotOnScreenOnly() {
        let windows: [[String: Any]] = [
            windowDict(pid: 42, number: 200, name: "Hidden", width: 800, height: 600, onScreen: false),
        ]

        let result = WindowListProvider.cgWindows(fromWindowList: windows, processIdentifier: 42, onScreenOnly: false)
        XCTAssertEqual(result.map(\.id), [200])
    }

    func test_framesMatchWithinTolerance() {
        let axPosition = CGPoint(x: 10, y: 20)
        let axSize = CGSize(width: 800, height: 600)
        let cgFrame = CGRect(x: 11, y: 19, width: 801, height: 599)
        XCTAssertTrue(WindowListProvider.framesMatch(axPosition: axPosition, axSize: axSize, cgFrame: cgFrame))
    }

    func test_framesMatchRejectsLargeDrift() {
        let axPosition = CGPoint(x: 10, y: 20)
        let axSize = CGSize(width: 800, height: 600)
        let cgFrame = CGRect(x: 50, y: 20, width: 800, height: 600)
        XCTAssertFalse(WindowListProvider.framesMatch(axPosition: axPosition, axSize: axSize, cgFrame: cgFrame))
    }

    func test_preferredTitlePrefersAccessibilityTitle() {
        XCTAssertEqual(
            WindowListProvider.preferredTitle(axTitle: "README.ko.md", cgTitle: ""),
            "README.ko.md"
        )
        XCTAssertEqual(
            WindowListProvider.preferredTitle(axTitle: "", cgTitle: "Fallback"),
            "Fallback"
        )
    }
}

final class WindowVisibilityFilterTests: XCTestCase {

    func test_rejectsThinOffScreenTabStrip() {
        let window: [String: Any] = [
            kCGWindowLayer as String: NSNumber(value: 0),
            kCGWindowIsOnscreen as String: NSNumber(value: false),
            kCGWindowAlpha as String: NSNumber(value: 1),
            kCGWindowBounds as String: ["Width": 2560, "Height": 30],
        ]
        XCTAssertFalse(WindowVisibilityFilter.passesOnScreenCGWindow(window))
    }

    func test_acceptsNormalOnScreenWindow() {
        let window: [String: Any] = [
            kCGWindowLayer as String: NSNumber(value: 0),
            kCGWindowIsOnscreen as String: NSNumber(value: true),
            kCGWindowAlpha as String: NSNumber(value: 1),
            kCGWindowBounds as String: ["Width": 2560, "Height": 1410],
        ]
        XCTAssertTrue(WindowVisibilityFilter.passesOnScreenCGWindow(window))
    }
}
