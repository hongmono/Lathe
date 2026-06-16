import XCTest
@testable import Lathe

final class SettingsViewLayoutTests: XCTestCase {

    func test_settingsContentUsesStableTopSpacing() {
        XCTAssertLessThanOrEqual(SettingsViewLayout.detailTopMargin, 32)
    }

    func test_settingsSidebarUsesResizableColumnWidths() {
        XCTAssertGreaterThan(SettingsViewLayout.sidebarMinWidth, 0)
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sidebarWidth, SettingsViewLayout.sidebarMinWidth)
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sidebarMaxWidth, SettingsViewLayout.sidebarWidth)
    }
}
