import XCTest
@testable import Lathe

final class CarouselLayoutTests: XCTestCase {

    func test_fanLayoutPlacesItemsAlongArcAroundFocusedCard() {
        let items = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .fan,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120
        )

        XCTAssertEqual(items.map(\.relativeIndex), [-2, -1, 0, 1, 2])
        XCTAssertEqual(items[0].angleDegrees, -26.44, accuracy: 0.01)
        XCTAssertEqual(items[1].angleDegrees, -13.22, accuracy: 0.01)
        XCTAssertEqual(items[2].angleDegrees, 0, accuracy: 0.001)
        XCTAssertEqual(items[3].angleDegrees, 13.22, accuracy: 0.01)
        XCTAssertEqual(items[4].angleDegrees, 26.44, accuracy: 0.01)
        XCTAssertEqual(items[2].offsetX, 0, accuracy: 0.001)
        XCTAssertEqual(items[2].offsetY, 0, accuracy: 0.001)
        XCTAssertEqual(items[1].offsetX, -118.94, accuracy: 0.01)
        XCTAssertEqual(items[3].offsetX, 118.94, accuracy: 0.01)
        XCTAssertEqual(items[1].offsetY, 13.78, accuracy: 0.01)
        XCTAssertEqual(items[3].offsetY, 13.78, accuracy: 0.01)
        XCTAssertGreaterThan(items[0].offsetY, items[1].offsetY)
        XCTAssertGreaterThan(items[4].offsetY, items[3].offsetY)
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

    func test_fanLayoutUsesLargerRadiusForGentlerAngles() {
        let compactRadiusItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 20,
            fanRadius: 480,
            fanSpacing: 120
        )
        let wideRadiusItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 20,
            fanRadius: 960,
            fanSpacing: 120
        )

        XCTAssertEqual(wideRadiusItems[2].angleDegrees, compactRadiusItems[2].angleDegrees / 2, accuracy: 0.001)
        XCTAssertLessThan(wideRadiusItems[2].offsetY, compactRadiusItems[2].offsetY)
    }

    func test_fanLayoutUsesConfiguredFanSpacingAsArcDistance() {
        let compactSpacingItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 12,
            fanRadius: 600,
            fanSpacing: 90
        )
        let wideSpacingItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 12,
            fanRadius: 600,
            fanSpacing: 180
        )

        XCTAssertEqual(wideSpacingItems[2].angleDegrees, compactSpacingItems[2].angleDegrees * 2, accuracy: 0.001)
        XCTAssertGreaterThan(wideSpacingItems[2].offsetX, compactSpacingItems[2].offsetX)
        XCTAssertGreaterThan(wideSpacingItems[2].offsetY, compactSpacingItems[2].offsetY)
    }

    func test_fanLayoutIgnoresGeneralSpacingToAvoidCompetingAngleControls() {
        let compactSpacingItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 6,
            fanRadius: 520,
            fanSpacing: 120
        )
        let wideSpacingItems = CarouselLayout.items(
            appCount: 3,
            selectedIndex: 1,
            style: .fan,
            angularStep: 28,
            fanRadius: 520,
            fanSpacing: 120
        )

        XCTAssertEqual(wideSpacingItems, compactSpacingItems)
    }

    func test_fanLayoutUsesReducedVisibleRangeToStayInsideOverlayPanel() {
        let items = CarouselLayout.items(
            appCount: 11,
            selectedIndex: 5,
            style: .fan,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120,
            maxVisibleEachSide: CarouselGeometry.maxVisibleEachSide(for: .fan)
        )

        XCTAssertEqual(items.map(\.relativeIndex), [-3, -2, -1, 0, 1, 2, 3])
        XCTAssertEqual(items[0].angleDegrees, -39.67, accuracy: 0.01)
        XCTAssertEqual(items[6].angleDegrees, 39.67, accuracy: 0.01)
    }

    func test_spaceLayoutKeepsOneDeckWhileDeemphasizingOtherSpaceApps() {
        let items = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 1,
            style: .space,
            angularStep: 12,
            currentSpaceIndices: [1, 2]
        )

        let focusedCurrentSpaceItem = try! XCTUnwrap(items.first { $0.index == 1 })
        let nearbyCurrentSpaceItem = try! XCTUnwrap(items.first { $0.index == 2 })
        let nearbyOtherSpaceItem = try! XCTUnwrap(items.first { $0.index == 0 })

        XCTAssertLessThan(focusedCurrentSpaceItem.offsetY, nearbyOtherSpaceItem.offsetY)
        XCTAssertLessThan(nearbyCurrentSpaceItem.offsetY, nearbyOtherSpaceItem.offsetY)
        XCTAssertLessThan(nearbyOtherSpaceItem.offsetY - nearbyCurrentSpaceItem.offsetY, 36)
        XCTAssertLessThan(nearbyOtherSpaceItem.scale, nearbyCurrentSpaceItem.scale)
        XCTAssertLessThan(nearbyOtherSpaceItem.opacity, nearbyCurrentSpaceItem.opacity)
    }

    func test_spaceLayoutCentersSingleCurrentSpaceApp() {
        let items = CarouselLayout.items(
            appCount: 4,
            selectedIndex: 2,
            style: .space,
            angularStep: 12,
            currentSpaceIndices: [2]
        )

        let currentSpaceItem = try! XCTUnwrap(items.first { $0.index == 2 })
        let otherSpaceItems = items.filter { $0.index != 2 }

        XCTAssertEqual(currentSpaceItem.offsetX, 0, accuracy: 0.001)
        XCTAssertTrue(otherSpaceItems.allSatisfy { currentSpaceItem.offsetY < $0.offsetY })
    }

    func test_spaceLayoutFallsBackToFanGeometryWithoutCurrentSpaceApps() {
        let spaceItems = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .space,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120
        )
        let fanItems = CarouselLayout.items(
            appCount: 5,
            selectedIndex: 2,
            style: .fan,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120
        )

        XCTAssertEqual(spaceItems, fanItems)
    }

    func test_spaceLayoutFallsBackToFanGeometryWhenCurrentSpaceAppsAreNotVisible() {
        let spaceItems = CarouselLayout.items(
            appCount: 8,
            selectedIndex: 6,
            style: .space,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120,
            maxVisibleEachSide: 1,
            currentSpaceIndices: [0, 1]
        )
        let fanItems = CarouselLayout.items(
            appCount: 8,
            selectedIndex: 6,
            style: .fan,
            angularStep: 12,
            fanRadius: 520,
            fanSpacing: 120,
            maxVisibleEachSide: 1
        )

        XCTAssertEqual(spaceItems, fanItems)
    }

    func test_spaceLayoutPreservesOrderWithinGroups() {
        let items = CarouselLayout.items(
            appCount: 6,
            selectedIndex: 2,
            style: .space,
            angularStep: 12,
            currentSpaceIndices: [1, 3]
        )

        let currentSpaceItems = items.filter { [1, 3].contains($0.index) }
        let otherSpaceItems = items.filter { ![1, 3].contains($0.index) }

        XCTAssertEqual(currentSpaceItems.map(\.index), [1, 3])
        XCTAssertEqual(otherSpaceItems.map(\.index), [0, 2, 4, 5])
        XCTAssertLessThan(currentSpaceItems[0].offsetX, currentSpaceItems[1].offsetX)
        XCTAssertLessThan(otherSpaceItems[0].offsetX, otherSpaceItems[1].offsetX)
    }
}
