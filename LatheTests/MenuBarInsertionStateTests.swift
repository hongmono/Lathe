import XCTest
@testable import Lathe

final class MenuBarInsertionStateTests: XCTestCase {

    func test_menuBarExtraStartsInserted() {
        XCTAssertTrue(MenuBarInsertionPolicy.initialValue)
    }

    func test_menuBarRemovalRequestKeepsExtraInserted() {
        XCTAssertTrue(MenuBarInsertionPolicy.resolve(false))
    }
}
