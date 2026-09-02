import XCTest
@testable import Lathe

final class WindowListLayoutTests: XCTestCase {
    func test_presentationOrderRunsTopToBottomForShortList() {
        let orders = (0..<4).map {
            WindowListLayout.presentationOrder(for: $0, selectedIndex: 0, itemCount: 4)
        }

        XCTAssertEqual(orders, [0, 1, 2, 3])
    }

    func test_presentationOrderUsesVisibleSliceAroundMiddleSelection() {
        let orders = (2...7).map {
            WindowListLayout.presentationOrder(for: $0, selectedIndex: 5, itemCount: 10)
        }

        XCTAssertEqual(orders, [0, 1, 2, 3, 4, 5])
    }

    func test_presentationOrderUsesLastVisibleSliceNearEnd() {
        let orders = (4...9).map {
            WindowListLayout.presentationOrder(for: $0, selectedIndex: 9, itemCount: 10)
        }

        XCTAssertEqual(orders, [0, 1, 2, 3, 4, 5])
    }
}
