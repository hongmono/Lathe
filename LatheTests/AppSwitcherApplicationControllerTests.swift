import XCTest
@testable import Lathe

final class AppSwitcherApplicationControllerTests: XCTestCase {
    func test_toggleHidden_hidesVisibleApplication() {
        let application = SpyApplication(bundleIdentifier: "com.example.editor", isHidden: false)

        XCTAssertTrue(AppSwitcherApplicationController.toggleHidden(application))

        XCTAssertEqual(application.events, [.hide])
        XCTAssertTrue(application.isHidden)
    }

    func test_toggleHidden_unhidesHiddenApplication() {
        let application = SpyApplication(bundleIdentifier: "com.example.editor", isHidden: true)

        XCTAssertTrue(AppSwitcherApplicationController.toggleHidden(application))

        XCTAssertEqual(application.events, [.unhide])
        XCTAssertFalse(application.isHidden)
    }

    func test_requestTermination_usesNormalTermination() {
        let application = SpyApplication(bundleIdentifier: "com.example.editor")

        XCTAssertTrue(AppSwitcherApplicationController.requestTermination(application))

        XCTAssertEqual(application.events, [.terminate])
    }

    func test_requestTermination_refusesFinder() {
        let application = SpyApplication(bundleIdentifier: AppSwitcherApplicationController.finderBundleIdentifier)

        XCTAssertFalse(AppSwitcherApplicationController.requestTermination(application))

        XCTAssertTrue(application.events.isEmpty)
    }

    private final class SpyApplication: SwitcherRunningApplication {
        enum Event: Equatable {
            case hide
            case unhide
            case terminate
        }

        let bundleIdentifier: String?
        var isHidden: Bool
        private(set) var events: [Event] = []

        init(bundleIdentifier: String?, isHidden: Bool = false) {
            self.bundleIdentifier = bundleIdentifier
            self.isHidden = isHidden
        }

        func hide() -> Bool {
            events.append(.hide)
            isHidden = true
            return true
        }

        func unhide() -> Bool {
            events.append(.unhide)
            isHidden = false
            return true
        }

        func terminate() -> Bool {
            events.append(.terminate)
            return true
        }
    }
}
