import XCTest
@testable import Lathe

final class SettingsPaneTests: XCTestCase {

    func test_sidebarPanesExposeNativeSettingsSectionsInOrder() {
        XCTAssertEqual(SettingsPane.sidebarPanes, [
            .general,
            .permissions,
            .carousel,
            .hiddenApps,
            .about,
        ])
        XCTAssertEqual(SettingsPane.general.titleKey, "settings.general.section")
        XCTAssertEqual(SettingsPane.permissions.titleKey, "settings.permissions.section")
        XCTAssertEqual(SettingsPane.permissions.systemImage, "hand.raised")
        XCTAssertEqual(SettingsPane.carousel.systemImage, "rectangle.stack")
        XCTAssertEqual(SettingsPane.hiddenApps.systemImage, "eye.slash")
        XCTAssertEqual(SettingsPane.about.titleKey, "settings.about.section")
    }
}
