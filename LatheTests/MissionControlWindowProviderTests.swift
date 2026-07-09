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

    func test_group_ordersByScreenThenFirstAppearance() {
        // 화면이 섞여 등장해도, 스택 배열은 화면0 전부 → 화면1 전부 순서여야 한다.
        let stacks = MissionControlWindowProvider.group([win(1, pid: 10, screen: 1),
                                                         win(2, pid: 20, screen: 0),
                                                         win(3, pid: 30, screen: 1),
                                                         win(4, pid: 40, screen: 0)])
        XCTAssertEqual(stacks.map(\.screenIndex), [0, 0, 1, 1])
        // 같은 화면 안에서는 첫 등장 순서 유지(stable).
        XCTAssertEqual(stacks.map { Int($0.appEntry.id) }, [20, 40, 10, 30])
    }

    func test_group_uniqueIDs() {
        let stacks = MissionControlWindowProvider.group([win(1, pid: 10, screen: 0),
                                                         win(2, pid: 11, screen: 0),
                                                         win(3, pid: 10, screen: 1)])
        XCTAssertEqual(Set(stacks.map(\.id)).count, stacks.count)
    }

    private func cgInfo(pid: Int, number: Int, x: Double, y: Double, w: Double, h: Double,
                        name: String, layer: Int = 0, alpha: Double = 1, onscreen: Bool = true) -> [String: Any] {
        [
            kCGWindowOwnerPID as String: NSNumber(value: pid),
            kCGWindowNumber as String: NSNumber(value: number),
            kCGWindowLayer as String: NSNumber(value: layer),
            kCGWindowAlpha as String: NSNumber(value: alpha),
            kCGWindowIsOnscreen as String: NSNumber(value: onscreen),
            kCGWindowName as String: name,
            kCGWindowBounds as String: ["X": NSNumber(value: x), "Y": NSNumber(value: y),
                                        "Width": NSNumber(value: w), "Height": NSNumber(value: h)],
        ]
    }

    private func app(_ pid: Int) -> AppEntry {
        AppEntry(id: pid_t(pid), bundleIdentifier: "x.\(pid)", name: "App\(pid)", icon: NSImage())
    }

    func test_mcWindows_keepsKnownApp_computesLocalFrameAndTitle() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800),
                       CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        let raw = [cgInfo(pid: 10, number: 1, x: 1100, y: 100, w: 300, h: 200, name: "W1")]
        let result = MissionControlWindowProvider.mcWindows(fromWindowList: raw,
                                                            appsByPID: [10: app(10)], screenFrames: screens,
                                                            requireTitle: true)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, 1)
        XCTAssertEqual(result[0].screenIndex, 1)
        XCTAssertEqual(result[0].localFrame.minX, 100)   // 1100 - 1000
        XCTAssertEqual(result[0].windowEntry.title, "W1")
        XCTAssertFalse(result[0].windowEntry.isMinimized)
    }

    func test_mcWindows_dropsUnknownAppAndTooSmall() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800)]
        let raw = [cgInfo(pid: 99, number: 1, x: 0, y: 0, w: 300, h: 200, name: "Other"),   // unknown pid
                   cgInfo(pid: 10, number: 2, x: 0, y: 0, w: 50, h: 50, name: "tiny")]        // < 200x80
        let result = MissionControlWindowProvider.mcWindows(fromWindowList: raw,
                                                            appsByPID: [10: app(10)], screenFrames: screens,
                                                            requireTitle: false)
        XCTAssertTrue(result.isEmpty)
    }

    func test_mcWindows_requireTitle_dropsUntitledAuxWindow() {
        // Aside 등: 실제 창 + 제목 없는 래퍼(그림자) 창. 권한 있으면 래퍼를 제외해 스택 중복을 막는다.
        let screens = [CGRect(x: 0, y: 0, width: 2560, height: 1410)]
        let raw = [cgInfo(pid: 10, number: 1, x: 0, y: 0, w: 2560, h: 1410, name: "Real"),
                   cgInfo(pid: 10, number: 2, x: -79, y: -79, w: 2718, h: 1568, name: "")]   // 래퍼
        let result = MissionControlWindowProvider.mcWindows(fromWindowList: raw,
                                                            appsByPID: [10: app(10)], screenFrames: screens,
                                                            requireTitle: true)
        XCTAssertEqual(result.map(\.id), [1])
    }

    func test_mcWindows_noPermission_keepsUntitled() {
        // 권한 없으면(requireTitle=false) CGWindowName을 못 믿으니 제목 없는 창도 유지(빈 화면 방지).
        let screens = [CGRect(x: 0, y: 0, width: 2560, height: 1410)]
        let raw = [cgInfo(pid: 10, number: 2, x: 0, y: 0, w: 2560, h: 1410, name: "")]
        let result = MissionControlWindowProvider.mcWindows(fromWindowList: raw,
                                                            appsByPID: [10: app(10)], screenFrames: screens,
                                                            requireTitle: false)
        XCTAssertEqual(result.map(\.id), [2])
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
