import AppKit
import XCTest
@testable import Lathe

final class MissionControlWindowProviderTests: XCTestCase {

    private func win(_ id: Int, pid: Int, screen: Int) -> MCWindow {
        let app = AppEntry(id: pid_t(pid), bundleIdentifier: "x.\(pid)", name: "App\(pid)", icon: NSImage())
        let entry = WindowEntry(id: id, title: "W\(id)", pathSummary: nil, isMinimized: false)
        return MCWindow(id: id, pid: pid_t(pid), appEntry: app, windowEntry: entry,
                        frame: .zero, localFrame: .zero, screenIndex: screen)
    }

    func test_group_samePidSameScreen_oneStackPreservingOrder() {
        let stacks = MissionControlWindowProvider.group([win(1, pid: 10, screen: 0),
                                                         win(2, pid: 10, screen: 0)])
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks[0].windows.map(\.id), [1, 2])
        XCTAssertEqual(stacks[0].frontIndex, 0)
        XCTAssertEqual(stacks[0].frontWindow.id, 1)
    }

    func test_group_samePidDifferentScreen_twoStacks() {
        let stacks = MissionControlWindowProvider.group([win(1, pid: 10, screen: 0),
                                                         win(2, pid: 10, screen: 1)])
        XCTAssertEqual(stacks.count, 2)
    }

    func test_group_differentPids_orderByFirstAppearance() {
        let stacks = MissionControlWindowProvider.group([win(1, pid: 20, screen: 0),
                                                         win(2, pid: 10, screen: 0),
                                                         win(3, pid: 20, screen: 0)])
        XCTAssertEqual(stacks.map { Int($0.appEntry.id) }, [20, 10])
        XCTAssertEqual(stacks[0].windows.map(\.id), [1, 3])
    }

    func test_group_uniqueIDs() {
        let stacks = MissionControlWindowProvider.group([win(1, pid: 10, screen: 0),
                                                         win(2, pid: 11, screen: 0),
                                                         win(3, pid: 10, screen: 1)])
        XCTAssertEqual(Set(stacks.map(\.id)).count, stacks.count)
    }

    func test_screenIndex_picksMaxOverlap() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800),
                       CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        // 대부분 두 번째 화면에 걸친 창.
        let frame = CGRect(x: 900, y: 100, width: 400, height: 300)
        XCTAssertEqual(MissionControlWindowProvider.screenIndex(forFrame: frame, screenFrames: screens), 1)
    }

    func test_screenIndex_noScreens_returnsNil() {
        XCTAssertNil(MissionControlWindowProvider.screenIndex(forFrame: .zero, screenFrames: []))
    }

    func test_screenIndex_fullyOnFirst() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800),
                       CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        let frame = CGRect(x: 100, y: 100, width: 200, height: 200)
        XCTAssertEqual(MissionControlWindowProvider.screenIndex(forFrame: frame, screenFrames: screens), 0)
    }
}
