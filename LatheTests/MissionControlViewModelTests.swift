import AppKit
import XCTest
@testable import Lathe

@MainActor
final class MissionControlViewModelTests: XCTestCase {
    private func win(_ id: Int, pid: Int, screen: Int = 0) -> MCWindow {
        let app = AppEntry(id: pid_t(pid), bundleIdentifier: "x.\(pid)", name: "App\(pid)", icon: NSImage())
        let entry = WindowEntry(id: id, title: "W\(id)", pathSummary: nil, isMinimized: false)
        return MCWindow(id: id, pid: pid_t(pid), appEntry: app, windowEntry: entry,
                        frame: .zero, localFrame: .zero, screenIndex: screen)
    }

    /// pid별 창 목록 → 스택 배열 (group 재사용).
    private func stacks(_ apps: [(pid: Int, windowIDs: [Int])]) -> [MCAppStack] {
        MissionControlWindowProvider.group(apps.flatMap { app in app.windowIDs.map { win($0, pid: app.pid) } })
    }

    func test_initialSelection_picksStackContainingWindow() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10]), (2, [20, 21]), (3, [30])]), selectedWindowID: 21)
        XCTAssertEqual(vm.currentStack?.appEntry.id, 2)
    }

    func test_next_movesBetweenStacks_wraps() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10]), (2, [20]), (3, [30])]), selectedWindowID: 10)
        XCTAssertEqual(vm.currentStack?.appEntry.id, 1)
        vm.next(); XCTAssertEqual(vm.currentStack?.appEntry.id, 2)
        vm.next(); vm.next(); XCTAssertEqual(vm.currentStack?.appEntry.id, 1)
    }

    func test_previous_wraps() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10]), (2, [20])]), selectedWindowID: 10)
        vm.previous(); XCTAssertEqual(vm.currentStack?.appEntry.id, 2)
    }

    func test_cycleWindow_movesFrontWithinSelectedStack_wraps() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10, 11, 12])]), selectedWindowID: 10)
        XCTAssertEqual(vm.currentWindow?.id, 10)
        vm.cycleWindow(); XCTAssertEqual(vm.currentWindow?.id, 11)
        vm.cycleWindow(); vm.cycleWindow(); XCTAssertEqual(vm.currentWindow?.id, 10)
        vm.cycleWindowPrevious(); XCTAssertEqual(vm.currentWindow?.id, 12)
    }

    func test_cycleWindow_singleWindowStack_noop() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10])]), selectedWindowID: 10)
        vm.cycleWindow()
        XCTAssertEqual(vm.currentWindow?.id, 10)
    }

    func test_cycleWindow_onlyAffectsSelectedStack() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10, 11]), (2, [20, 21])]), selectedWindowID: 10)
        vm.cycleWindow()                       // 스택1 front → 11
        vm.next()                              // 스택2 선택
        XCTAssertEqual(vm.currentWindow?.id, 20)   // 스택2는 그대로
    }

    func test_empty_currentNil() {
        let vm = MissionControlViewModel()
        vm.set(stacks: [], selectedWindowID: nil)
        XCTAssertNil(vm.currentStack)
        XCTAssertNil(vm.currentWindow)
    }

    func test_setThumbnail_keepsSelection() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10]), (2, [20])]), selectedWindowID: 20)
        vm.setThumbnail(NSImage(), forWindowID: 10)
        XCTAssertEqual(vm.currentStack?.appEntry.id, 2)
        XCTAssertNotNil(vm.thumbnails[10])
    }

    func test_pick_selectsStackAndFiresCommit() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10]), (2, [20])]), selectedWindowID: 10)
        var committed = false
        vm.onCommit = { committed = true }
        let target = vm.stacks.first { $0.appEntry.id == 2 }!.id
        vm.pick(stackID: target)
        XCTAssertEqual(vm.currentStack?.appEntry.id, 2)   // 클릭한 스택이 선택됨
        XCTAssertTrue(committed)                          // 확정 콜백 발화
    }

    func test_pick_unknownStack_noCommit() {
        let vm = MissionControlViewModel()
        vm.set(stacks: stacks([(1, [10])]), selectedWindowID: 10)
        var committed = false
        vm.onCommit = { committed = true }
        vm.pick(stackID: 999999)
        XCTAssertFalse(committed)
    }
}
