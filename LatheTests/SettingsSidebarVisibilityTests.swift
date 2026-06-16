import XCTest
@testable import Lathe

final class SettingsSidebarVisibilityTests: XCTestCase {

    func test_sidebarUsesStableLayoutDimensions() {
        XCTAssertGreaterThan(SettingsViewLayout.sidebarMinWidth, 0)
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sidebarWidth, SettingsViewLayout.sidebarMinWidth)
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sidebarMaxWidth, SettingsViewLayout.sidebarWidth)
    }

    func test_sidebarUsesSettingsPaneMenuItems() {
        XCTAssertEqual(SettingsPane.sidebarPanes, [
            .general,
            .permissions,
            .carousel,
            .hiddenApps,
            .about,
        ])
    }
}
