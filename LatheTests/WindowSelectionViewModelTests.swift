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

    private final class StubBrowserTabProvider: BrowserTabProviding {
        var tabs: [BrowserTabEntry] = []
        private(set) var activatedTabIDs: [String] = []

        func tabs(forProcessIdentifier pid: pid_t, windows: [WindowEntry]) -> [BrowserTabEntry] {
            tabs
        }

        func activate(tab: BrowserTabEntry) -> Bool {
            activatedTabIDs.append(tab.id)
            return true
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

    func test_cyclingDoesNotChangePreferredWindowUntilActivation() {
        let pid: pid_t = 42
        let entries = [
            WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false),
            WindowEntry(id: 2, title: "Two", pathSummary: nil, isMinimized: false),
        ]
        let listing = StubWindowListing()
        listing.windowsByPID[pid] = entries
        let tracker = WindowFocusTracker(windowListProvider: listing)
        let viewModel = WindowSelectionViewModel(focusTracker: tracker)
        viewModel.load(forProcessIdentifier: pid)

        viewModel.next()

        let reloadedViewModel = WindowSelectionViewModel(focusTracker: tracker)
        reloadedViewModel.load(forProcessIdentifier: pid)
        XCTAssertEqual(reloadedViewModel.currentWindow?.id, 1)
    }

    func test_browserTabsReplaceWindowItemsWhenEnabled() {
        let pid: pid_t = 42
        let window = WindowEntry(id: 1, title: "Browser", pathSummary: nil, isMinimized: false)
        let listing = StubWindowListing()
        listing.windowsByPID[pid] = [window]
        let tabs = StubBrowserTabProvider()
        tabs.tabs = [
            BrowserTabEntry(id: "first", title: "First", windowOrdinal: 1, window: window, isSelected: false),
            BrowserTabEntry(id: "second", title: "Second", windowOrdinal: 1, window: window, isSelected: true),
        ]
        let viewModel = WindowSelectionViewModel(
            focusTracker: WindowFocusTracker(windowListProvider: listing),
            browserTabProvider: tabs,
            browserTabsEnabled: { true }
        )

        viewModel.load(forProcessIdentifier: pid)

        XCTAssertTrue(viewModel.hasMultipleItems)
        XCTAssertEqual(viewModel.currentBrowserTab?.id, "second")
        XCTAssertEqual(viewModel.currentWindow?.id, window.id)
    }

    func test_browserTabsRemainUnusedWhenOptionIsDisabled() {
        let pid: pid_t = 42
        let windows = [
            WindowEntry(id: 1, title: "One", pathSummary: nil, isMinimized: false),
            WindowEntry(id: 2, title: "Two", pathSummary: nil, isMinimized: false),
        ]
        let listing = StubWindowListing()
        listing.windowsByPID[pid] = windows
        let tabs = StubBrowserTabProvider()
        tabs.tabs = [
            BrowserTabEntry(id: "first", title: "First", windowOrdinal: 1, window: windows[0], isSelected: true),
            BrowserTabEntry(id: "second", title: "Second", windowOrdinal: 1, window: windows[0], isSelected: false),
        ]
        let viewModel = WindowSelectionViewModel(
            focusTracker: WindowFocusTracker(windowListProvider: listing),
            browserTabProvider: tabs,
            browserTabsEnabled: { false }
        )

        viewModel.load(forProcessIdentifier: pid)

        XCTAssertNil(viewModel.currentBrowserTab)
        XCTAssertEqual(viewModel.currentWindow?.id, windows[0].id)
    }

    func test_prepareSelectionActivatesCurrentBrowserTab() {
        let pid: pid_t = 42
        let window = WindowEntry(id: 1, title: "Browser", pathSummary: nil, isMinimized: false)
        let listing = StubWindowListing()
        listing.windowsByPID[pid] = [window]
        let tabs = StubBrowserTabProvider()
        tabs.tabs = [
            BrowserTabEntry(id: "first", title: "First", windowOrdinal: 1, window: window, isSelected: true),
            BrowserTabEntry(id: "second", title: "Second", windowOrdinal: 1, window: window, isSelected: false),
        ]
        let viewModel = WindowSelectionViewModel(
            focusTracker: WindowFocusTracker(windowListProvider: listing),
            browserTabProvider: tabs,
            browserTabsEnabled: { true }
        )
        viewModel.load(forProcessIdentifier: pid)
        viewModel.next()

        viewModel.prepareSelectionForActivation()

        XCTAssertEqual(tabs.activatedTabIDs, ["second"])
    }
}
