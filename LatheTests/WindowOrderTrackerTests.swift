import XCTest
@testable import Lathe

final class WindowOrderTrackerTests: XCTestCase {

    private func entry(_ id: Int, title: String = "Window") -> WindowEntry {
        WindowEntry(id: id, title: title, pathSummary: nil, isMinimized: false)
    }

    func test_touchMovesWindowToFront() {
        var tracker = WindowOrderTracker()
        tracker.touch(windowID: 1, processIdentifier: 42)
        tracker.touch(windowID: 2, processIdentifier: 42)
        tracker.touch(windowID: 1, processIdentifier: 42)

        let ordered = tracker.orderedEntries([entry(1), entry(2), entry(3)], processIdentifier: 42)
        XCTAssertEqual(ordered.map(\.id), [1, 2, 3])
    }

    func test_reconcileRemovesClosedWindowsAndAppendsNewOnes() {
        var tracker = WindowOrderTracker()
        tracker.touch(windowID: 1, processIdentifier: 42)
        tracker.touch(windowID: 2, processIdentifier: 42)
        tracker.reconcile(processIdentifier: 42, liveWindowIDs: [2, 3])

        let ordered = tracker.orderedEntries([entry(2), entry(3)], processIdentifier: 42)
        XCTAssertEqual(ordered.map(\.id), [2, 3])
    }

    func test_preferredIndexUsesMRUWindow() {
        var tracker = WindowOrderTracker()
        tracker.touch(windowID: 2, processIdentifier: 42)
        tracker.touch(windowID: 1, processIdentifier: 42)

        let entries = [entry(1), entry(2), entry(3)]
        XCTAssertEqual(tracker.preferredIndex(for: entries, processIdentifier: 42), 0)
    }
}
