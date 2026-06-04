import XCTest
import CoreGraphics
@testable import Lathe

final class HotKeyActionTests: XCTestCase {

    func test_commandTabRequestsNext() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x30, commandDown: true, shiftDown: false, arrowsEnabled: false),
            .next
        )
    }

    func test_commandShiftTabRequestsPrevious() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x30, commandDown: true, shiftDown: true, arrowsEnabled: false),
            .previous
        )
    }

    func test_commandEscapeRequestsCancel() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x35, commandDown: true, shiftDown: false, arrowsEnabled: false),
            .cancel
        )
    }

    func test_rightArrowRequestsNextWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x7C, commandDown: false, shiftDown: false, arrowsEnabled: true),
            .next
        )
    }

    func test_leftArrowRequestsPreviousWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x7B, commandDown: false, shiftDown: false, arrowsEnabled: true),
            .previous
        )
    }

    func test_arrowKeysAreIgnoredWhenArrowsAreDisabled() {
        XCTAssertNil(
            HotKeyAction.resolve(keyCode: 0x7C, commandDown: false, shiftDown: false, arrowsEnabled: false)
        )
    }

    func test_arrowKeysStillWorkWithCommandHeldWhenArrowsEnabled() {
        XCTAssertEqual(
            HotKeyAction.resolve(keyCode: 0x7C, commandDown: true, shiftDown: false, arrowsEnabled: true),
            .next
        )
    }
}
