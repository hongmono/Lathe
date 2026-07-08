import XCTest
@testable import Lathe

@MainActor
final class WindowSelectionViewModelTests: XCTestCase {

    private final class StubWindowListing: WindowListing {
        var windowsByPID: [pid_t: [WindowEntry]] = [:]

        func windows(forProcessIdentifier pid: pid_t) -> [WindowEntry] {
            windowsByPID[pid] ?? []
        }
    }

    private func makeViewModel(windows: [WindowEntry] = [], pid: pid_t = 42) -> WindowSelectionViewModel {
        let listing = StubWindowListing()
        listing.windowsByPID[pid] = windows
        let tracker = WindowFocusTracker(windowListProvider: listing)
        let viewModel = WindowSelectionViewModel(focusTracker: tracker)
        viewModel.load(forProcessIdentifier: pid)
        return viewModel
    }

    func test_loadClearsWindowsWhenProcessIdentifierIsNil() {
        let listing = StubWindowListing()
        let tracker = WindowFocusTracker(windowListProvider: listing)
        let viewModel = WindowSelectionViewModel(focusTracker: tracker)
        viewModel.load(forProcessIdentifier: 42)
        viewModel.load(forProcessIdentifier: nil)

        XCTAssertTrue(viewModel.windows.isEmpty)
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertFalse(viewModel.hasMultipleWindows)
    }

    func test_hasMultipleWindowsRequiresMoreThanOneEntry() {
        let single = makeViewModel(windows: [WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false)])
        XCTAssertFalse(single.hasMultipleWindows)

        let multiple = makeViewModel(windows: [
            WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false),
            WindowEntry(id: 2, title: "Two", pathSummary: nil, isMinimized: false),
        ])
        XCTAssertTrue(multiple.hasMultipleWindows)
    }

    func test_nextWrapsAround() {
        let viewModel = makeViewModel(windows: [
            WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false),
            WindowEntry(id: 2, title: "Two", pathSummary: nil, isMinimized: false),
        ])
        viewModel.next()
        XCTAssertEqual(viewModel.currentWindow?.id, 2)
        viewModel.next()
        XCTAssertEqual(viewModel.currentWindow?.id, 1)
    }

    func test_previousWrapsAround() {
        let viewModel = makeViewModel(windows: [
            WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false),
            WindowEntry(id: 2, title: "Two", pathSummary: nil, isMinimized: false),
        ])
        viewModel.previous()
        XCTAssertEqual(viewModel.currentWindow?.id, 2)
    }
}
