import XCTest
@testable import Lathe

final class SettingsSidebarVisibilityTests: XCTestCase {

    func test_sidebarUsesStableLayoutDimensions() {
        XCTAssertGreaterThan(SettingsViewLayout.sidebarWidth, 0)
        XCTAssertGreaterThan(SettingsViewLayout.sidebarOuterPadding, 0)
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sidebarContentTopPadding, 0)
    }

    func test_sidebarUsesSettingsPaneMenuItems() {
        XCTAssertEqual(SettingsPane.sidebarPanes, [
            .general,
            .carousel,
            .hiddenApps,
            .about,
        ])
    }
}
