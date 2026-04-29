import XCTest
@testable import Lathe

final class CarouselLayoutTests: XCTestCase {

    func test_fanLayoutRotatesItemsAroundFocusedCard() {
        let items = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .fan,
            angularStep: 12
        )

        XCTAssertEqual(items.map(\.relativeIndex), [-2, -1, 0, 1, 2])
        XCTAssertEqual(items.map(\.angleDegrees), [-24, -12, 0, 12, 24])
        XCTAssertEqual(items.first?.offsetX, 0)
    }

    func test_stripLayoutOffsetsItemsHorizontallyWithoutRotation() {
        let items = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .strip,
            angularStep: 12
        )

        XCTAssertEqual(items.map(\.angleDegrees), [0, 0, 0, 0, 0])
        XCTAssertEqual(items.map(\.offsetX), [-240, -120, 0, 120, 240])
    }

    func test_stackLayoutOverlapsItemsAndKeepsFocusedCardLargest() {
        let items = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .stack,
            angularStep: 12
        )

        XCTAssertEqual(items.map(\.offsetX), [-64, -32, 0, 32, 64])
        XCTAssertEqual(items[2].scale, 1.06, accuracy: 0.001)
        XCTAssertLessThan(items[1].scale, items[2].scale)
        XCTAssertLessThan(items[0].scale, items[1].scale)
    }
}
