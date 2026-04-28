import XCTest
import AppKit
@testable import Lathe

final class CarouselViewModelTests: XCTestCase {

    private func makeApps(_ n: Int) -> [AppEntry] {
        (0..<n).map { i in
            AppEntry(id: pid_t(i + 1000), bundleIdentifier: "id.\(i)", name: "App\(i)", icon: NSImage())
        }
    }

    @MainActor
    func test_initialState_selectedIndexZero() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 0)
        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.apps.count, 3)
    }

    @MainActor
    func test_next_wrapsAround() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 2)
        vm.next()
        XCTAssertEqual(vm.selectedIndex, 0)
    }

    @MainActor
    func test_previous_wrapsAround() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 0)
        vm.previous()
        XCTAssertEqual(vm.selectedIndex, 2)
    }

    @MainActor
    func test_emptyApps_nextIsNoOp() {
        let vm = CarouselViewModel()
        vm.update(apps: [], selectedIndex: 0)
        vm.next()
        XCTAssertEqual(vm.selectedIndex, 0)
    }

    @MainActor
    func test_updateApps_clampsSelectedIndex() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(5), selectedIndex: 4)
        vm.replaceApps(makeApps(2))
        XCTAssertEqual(vm.selectedIndex, 1)
    }

    @MainActor
    func test_currentEntry_returnsSelectedApp() {
        let vm = CarouselViewModel()
        let apps = makeApps(3)
        vm.update(apps: apps, selectedIndex: 1)
        XCTAssertEqual(vm.currentEntry?.id, apps[1].id)
    }
}
