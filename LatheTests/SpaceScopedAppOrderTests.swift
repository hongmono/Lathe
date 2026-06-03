import XCTest
@testable import Lathe

final class SpaceScopedAppOrderTests: XCTestCase {

    func test_orderedProcessIdentifiersKeepsSeparateMemoryPerSpace() {
        var order = SpaceScopedAppOrder()
        order.reconcileLiveProcessIdentifiers([10, 20, 30, 40])

        order.touch(pid: 20, currentSpaceProcessIdentifiers: [10, 20])
        order.touch(pid: 10, currentSpaceProcessIdentifiers: [10, 20])

        order.touch(pid: 40, currentSpaceProcessIdentifiers: [30, 40])
        order.touch(pid: 30, currentSpaceProcessIdentifiers: [30, 40])

        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: [10, 20]),
            [10, 20, 30, 40]
        )
        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: [30, 40]),
            [30, 40, 10, 20]
        )
    }

    func test_orderedProcessIdentifiersCarriesMemoryWhenSpaceAppSetChanges() {
        var order = SpaceScopedAppOrder()
        order.reconcileLiveProcessIdentifiers([10, 20, 30])
        order.touch(pid: 20, currentSpaceProcessIdentifiers: [10, 20])
        order.touch(pid: 10, currentSpaceProcessIdentifiers: [10, 20])

        order.reconcileLiveProcessIdentifiers([10, 20, 30, 40])

        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: [10, 20, 40]),
            [10, 20, 40, 30]
        )
    }

    func test_touchOutsideCurrentSpaceUpdatesOnlyGlobalOrder() {
        var order = SpaceScopedAppOrder()
        order.reconcileLiveProcessIdentifiers([10, 20, 30])
        order.touch(pid: 20, currentSpaceProcessIdentifiers: [10, 20])
        order.touch(pid: 10, currentSpaceProcessIdentifiers: [10, 20])
        order.touch(pid: 30, currentSpaceProcessIdentifiers: [10, 20])

        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: [10, 20]),
            [10, 20, 30]
        )
        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: []),
            [30, 10, 20]
        )
    }

    func test_reconcileLiveProcessIdentifiersRemovesTerminatedApps() {
        var order = SpaceScopedAppOrder()
        order.reconcileLiveProcessIdentifiers([10, 20, 30])
        order.touch(pid: 30, currentSpaceProcessIdentifiers: [20, 30])
        order.reconcileLiveProcessIdentifiers([10, 20])

        XCTAssertEqual(
            order.orderedProcessIdentifiers(currentSpaceProcessIdentifiers: [20]),
            [20, 10]
        )
    }
}
