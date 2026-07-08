import AppKit
import XCTest
@testable import Lathe

final class AppEntryFilteringTests: XCTestCase {

    func test_visibleInCarouselExcludesAppsByBundleIdentifier() {
        let apps = [
            AppEntry(id: 1, bundleIdentifier: "com.apple.finder", name: "Finder", icon: NSImage()),
            AppEntry(id: 2, bundleIdentifier: nil, name: "Unbundled", icon: NSImage()),
            AppEntry(id: 3, bundleIdentifier: "com.example.browser", name: "Browser", icon: NSImage()),
        ]

        let visible = AppEntry.visibleInCarousel(
            apps,
            excludingBundleIdentifiers: ["com.apple.finder"]
        )

        XCTAssertEqual(visible.map(\.id), [2, 3])
    }
}

final class AppActivatorTests: XCTestCase {

    func test_activateUnhidesActivatesAllWindowsAndRaisesProcessWindows() {
        let app = SpyRunningApplication(processIdentifier: 123)
        let windowRaiser = SpyWindowRaiser()

        AppActivator.activate(app, window: nil, windowRaiser: windowRaiser)

        XCTAssertEqual(app.events, [.unhide, .activate])
        XCTAssertEqual(app.activationOptions, [.activateAllWindows])
        XCTAssertEqual(windowRaiser.raisedProcessIdentifiers, [123])
        XCTAssertTrue(windowRaiser.raisedWindowRequests.isEmpty)
    }

    func test_activateSpecificWindowUsesIgnoringOtherAppsAndRaisesWindow() {
        let app = SpyRunningApplication(processIdentifier: 123)
        let windowRaiser = SpyWindowRaiser()
        let window = WindowEntry(id: 555, title: "Doc", pathSummary: nil, isMinimized: false)

        AppActivator.activate(app, window: window, windowRaiser: windowRaiser)

        XCTAssertEqual(app.events, [.unhide, .activate])
        XCTAssertEqual(app.activationOptions, [.activateIgnoringOtherApps])
        XCTAssertTrue(windowRaiser.raisedProcessIdentifiers.isEmpty)
        XCTAssertEqual(windowRaiser.raisedWindowRequests.count, 1)
        XCTAssertEqual(windowRaiser.raisedWindowRequests[0].0, 555)
        XCTAssertEqual(windowRaiser.raisedWindowRequests[0].1, 123)
    }

    func test_raisePlanRaisesVisibleWindowsAndRestoresNothing() {
        let plan = AccessibilityWindowRaiser.raisePlan(minimized: [true, false, true, false])

        XCTAssertNil(plan.unminimize)
        XCTAssertEqual(plan.raise, [1, 3])
    }

    func test_raisePlanRestoresOnlyMostRecentWhenAllMinimized() {
        let plan = AccessibilityWindowRaiser.raisePlan(minimized: [true, true, true])

        XCTAssertEqual(plan.unminimize, 0)
        XCTAssertEqual(plan.raise, [0])
    }

    func test_raisePlanDoesNothingWhenNoWindows() {
        let plan = AccessibilityWindowRaiser.raisePlan(minimized: [])

        XCTAssertNil(plan.unminimize)
        XCTAssertEqual(plan.raise, [])
    }

    private final class SpyRunningApplication: RunningApplicationActivating {
        enum Event: Equatable {
            case unhide
            case activate
        }

        let processIdentifier: pid_t
        private(set) var events: [Event] = []
        private(set) var activationOptions: NSApplication.ActivationOptions = []

        init(processIdentifier: pid_t) {
            self.processIdentifier = processIdentifier
        }

        func unhide() -> Bool {
            events.append(.unhide)
            return true
        }

        func activate(options: NSApplication.ActivationOptions) -> Bool {
            events.append(.activate)
            activationOptions = options
            return true
        }
    }

    private final class SpyWindowRaiser: ApplicationWindowRaising, SpecificWindowRaising {
        private(set) var raisedProcessIdentifiers: [pid_t] = []
        private(set) var raisedWindowRequests: [(Int, pid_t)] = []

        func raiseWindows(forProcessIdentifier processIdentifier: pid_t) {
            raisedProcessIdentifiers.append(processIdentifier)
        }

        @discardableResult
        func raiseWindow(_ windowID: Int, forProcessIdentifier processIdentifier: pid_t) -> Bool {
            raisedWindowRequests.append((windowID, processIdentifier))
            return false
        }
    }
}
