import XCTest
@testable import Lathe

@MainActor
final class MissionControlViewModelTests: XCTestCase {
    private func window(_ id: Int) -> MCWindow {
        let app = AppEntry(id: pid_t(id), bundleIdentifier: "x.\(id)", name: "App\(id)", icon: NSImage())
        let entry = WindowEntry(id: id, title: "W\(id)", pathSummary: nil, isMinimized: false)
        return MCWindow(id: id, pid: pid_t(id), appEntry: app, windowEntry: entry,
                        frame: .zero, localFrame: .zero, screenIndex: 0)
    }

    func test_next_wraps() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2), window(3)], selectedWindowID: 1)
        XCTAssertEqual(vm.currentWindow?.id, 1)
        vm.next(); XCTAssertEqual(vm.currentWindow?.id, 2)
        vm.next(); vm.next(); XCTAssertEqual(vm.currentWindow?.id, 1)
    }

    func test_previous_wraps() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2)], selectedWindowID: 1)
        vm.previous(); XCTAssertEqual(vm.currentWindow?.id, 2)
    }

    func test_initialSelection_matchesGivenID() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2), window(3)], selectedWindowID: 3)
        XCTAssertEqual(vm.currentWindow?.id, 3)
    }

    func test_empty_currentWindowNil() {
        let vm = MissionControlViewModel()
        vm.set(windows: [], selectedWindowID: nil)
        XCTAssertNil(vm.currentWindow)
    }

    func test_setThumbnail_keepsSelection() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2)], selectedWindowID: 2)
        vm.setThumbnail(NSImage(), forWindowID: 1)
        XCTAssertEqual(vm.currentWindow?.id, 2)
        XCTAssertNotNil(vm.thumbnails[1])
    }
}
