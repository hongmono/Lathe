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
    func test_prepareAnimatedPresentationStartsCollapsedThenExpands() {
        let vm = CarouselViewModel()

        vm.preparePresentation(apps: makeApps(3), selectedIndex: 1, animated: true)

        XCTAssertFalse(vm.isPresentationExpanded)
        XCTAssertEqual(vm.selectedIndex, 1)

        vm.completePresentation()

        XCTAssertTrue(vm.isPresentationExpanded)
    }

    @MainActor
    func test_prepareNonanimatedPresentationStartsExpanded() {
        let vm = CarouselViewModel()

        vm.preparePresentation(apps: makeApps(3), selectedIndex: 1, animated: false)

        XCTAssertTrue(vm.isPresentationExpanded)
    }

    @MainActor
    func test_next_wrapsAround() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 2)
        vm.next()
        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.selectionPosition, 3)
        XCTAssertEqual(vm.selectionDirection, 1)
    }

    @MainActor
    func test_previous_wrapsAround() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 0)
        vm.previous()
        XCTAssertEqual(vm.selectedIndex, 2)
        XCTAssertEqual(vm.selectionPosition, -1)
        XCTAssertEqual(vm.selectionDirection, -1)
    }

    @MainActor
    func test_emptyApps_nextIsNoOp() {
        let vm = CarouselViewModel()
        vm.update(apps: [], selectedIndex: 0)
        vm.next()
        XCTAssertEqual(vm.selectedIndex, 0)
    }

    @MainActor
    func test_singleApp_navigationKeepsStablePosition() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(1), selectedIndex: 0)

        vm.next()
        vm.previous()

        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.selectionPosition, 0)
        XCTAssertEqual(vm.selectionDirection, 0)
    }

    @MainActor
    func test_updateApps_clampsSelectedIndex() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(5), selectedIndex: 4)
        vm.replaceApps(makeApps(2))
        XCTAssertEqual(vm.selectedIndex, 1)
    }

    @MainActor
    func test_replaceApps_keepsSelectionByPid_whenOrderShifts() {
        let vm = CarouselViewModel()
        let apps = makeApps(3)
        vm.update(apps: apps, selectedIndex: 0)
        // 같은 앱들을 순서만 뒤집어 재공급: 인덱스는 바뀌어도 선택은 같은 pid를 가리켜야 한다.
        vm.replaceApps(apps.reversed())
        XCTAssertEqual(vm.currentEntry?.id, apps[0].id)
        XCTAssertEqual(vm.selectedIndex, 2)
    }

    @MainActor
    func test_replaceApps_preservesContinuousPosition_whenPidOrderIsUnchanged() {
        let vm = CarouselViewModel()
        vm.update(apps: makeApps(3), selectedIndex: 2)
        vm.next()

        vm.replaceApps(makeApps(3))

        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.selectionPosition, 3)
        XCTAssertEqual(vm.selectionDirection, 1)
    }

    @MainActor
    func test_currentEntry_returnsSelectedApp() {
        let vm = CarouselViewModel()
        let apps = makeApps(3)
        vm.update(apps: apps, selectedIndex: 1)
        XCTAssertEqual(vm.currentEntry?.id, apps[1].id)
    }

    @MainActor
    func test_removeApplication_selectsNextAppAtSameIndex() {
        let vm = CarouselViewModel()
        let apps = makeApps(4)
        vm.update(apps: apps, selectedIndex: 1)

        vm.removeApplication(processIdentifier: apps[1].id)

        XCTAssertEqual(vm.apps.map(\.id), [apps[0].id, apps[2].id, apps[3].id])
        XCTAssertEqual(vm.currentEntry?.id, apps[2].id)
    }

    @MainActor
    func test_removeLastApplication_clampsSelectionToPreviousApp() {
        let vm = CarouselViewModel()
        let apps = makeApps(3)
        vm.update(apps: apps, selectedIndex: 2)

        vm.removeApplication(processIdentifier: apps[2].id)

        XCTAssertEqual(vm.currentEntry?.id, apps[1].id)
    }
}
