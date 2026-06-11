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

        AppActivator.activate(app, windowRaiser: windowRaiser)

        XCTAssertEqual(app.events, [.unhide, .activate])
        XCTAssertEqual(app.activationOptions, [.activateAllWindows])
        XCTAssertEqual(windowRaiser.raisedProcessIdentifiers, [123])
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

    private final class SpyWindowRaiser: ApplicationWindowRaising {
        private(set) var raisedProcessIdentifiers: [pid_t] = []

        func raiseWindows(forProcessIdentifier processIdentifier: pid_t) {
            raisedProcessIdentifiers.append(processIdentifier)
        }
    }
}
