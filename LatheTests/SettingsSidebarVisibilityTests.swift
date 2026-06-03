import SwiftUI
import XCTest
@testable import Lathe

final class SettingsSidebarVisibilityTests: XCTestCase {

    func test_toggleHidesVisibleSidebar() {
        XCTAssertEqual(SettingsSidebarVisibilityToggle.toggled(.all), .detailOnly)
        XCTAssertEqual(SettingsSidebarVisibilityToggle.toggled(.automatic), .detailOnly)
        XCTAssertEqual(SettingsSidebarVisibilityToggle.toggled(.doubleColumn), .detailOnly)
    }

    func test_toggleShowsHiddenSidebar() {
        XCTAssertEqual(SettingsSidebarVisibilityToggle.toggled(.detailOnly), .all)
    }
}
