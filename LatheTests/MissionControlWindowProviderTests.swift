import XCTest
@testable import Lathe

final class MissionControlWindowProviderTests: XCTestCase {
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
