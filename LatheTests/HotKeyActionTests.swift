import XCTest
import CoreGraphics
@testable import Lathe

final class HotKeyActionTests: XCTestCase {

    func test_commandTabRequestsNext() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x30,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: false
            ),
            .next
        )
    }

    func test_commandShiftTabRequestsPrevious() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x30,
                commandDown: true,
                shiftDown: true,
                overlayActionsEnabled: false,
                windowCycleEnabled: false
            ),
            .previous
        )
    }

    func test_commandEscapeRequestsCancel() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x35,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: false
            ),
            .cancel
        )
    }

    func test_rightArrowRequestsNextWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x7C,
                commandDown: false,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: false
            ),
            .next
        )
    }

    func test_leftArrowRequestsPreviousWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x7B,
                commandDown: false,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: false
            ),
            .previous
        )
    }

    func test_arrowKeysAreIgnoredWhenArrowsAreDisabled() {
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x7C,
                commandDown: false,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: false
            )
        )
    }

    func test_arrowKeysStillWorkWithCommandHeldWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x7C,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: false
            ),
            .next
        )
    }

    func test_commandGraveRequestsCycleWindowWhenEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x32,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            ),
            .cycleWindow
        )
    }

    func test_commandShiftGraveRequestsCycleWindowPreviousWhenEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x32,
                commandDown: true,
                shiftDown: true,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            ),
            .cycleWindowPrevious
        )
    }

    func test_commandGraveIsIgnoredWhenWindowCycleDisabled() {
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x32,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: false
            )
        )
    }

    func test_commandCommaRequestsSettingsWhenOverlayIsVisible() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x2B,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            ),
            .openSettings
        )
    }

    func test_commandCommaIsIgnoredWhenOverlayIsHidden() {
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x2B,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            )
        )
    }

    func test_commandHRequestsToggleHiddenWhenOverlayIsVisible() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x04,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            ),
            .toggleSelectedApplicationHidden
        )
    }

    func test_commandQRequestsQuitWhenOverlayIsVisible() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x0C,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            ),
            .quitSelectedApplication
        )
    }

    func test_applicationManagementKeysAreIgnoredWhenOverlayIsHidden() {
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x04,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            )
        )
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x0C,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            )
        )
    }

    func test_shiftedApplicationManagementKeysAreNotConsumed() {
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x04,
                commandDown: true,
                shiftDown: true,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            )
        )
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x0C,
                commandDown: true,
                shiftDown: true,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            )
        )
    }

    func test_commandPeriodCancelsOnlyWhenOverlayIsVisible() {
        XCTAssertEqual(
            HotKeyAction.resolve(
                keyCode: 0x2F,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: true,
                windowCycleEnabled: true
            ),
            .cancel
        )
        XCTAssertNil(
            HotKeyAction.resolve(
                keyCode: 0x2F,
                commandDown: true,
                shiftDown: false,
                overlayActionsEnabled: false,
                windowCycleEnabled: true
            )
        )
    }

    func test_onlyNavigationActionsAcceptAutoRepeat() {
        XCTAssertTrue(HotKeyAction.next.acceptsAutoRepeat)
        XCTAssertTrue(HotKeyAction.previous.acceptsAutoRepeat)
        XCTAssertTrue(HotKeyAction.cycleWindow.acceptsAutoRepeat)
        XCTAssertTrue(HotKeyAction.cycleWindowPrevious.acceptsAutoRepeat)
        XCTAssertFalse(HotKeyAction.toggleSelectedApplicationHidden.acceptsAutoRepeat)
        XCTAssertFalse(HotKeyAction.quitSelectedApplication.acceptsAutoRepeat)
        XCTAssertFalse(HotKeyAction.openSettings.acceptsAutoRepeat)
        XCTAssertFalse(HotKeyAction.cancel.acceptsAutoRepeat)
    }
}
