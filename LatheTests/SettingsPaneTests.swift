import XCTest
@testable import Lathe

final class SettingsPaneTests: XCTestCase {

    func test_hiddenAppsPaneReturnsToMainSettingsPane() {
        XCTAssertEqual(SettingsPane.hiddenApps.backDestination, .main)
        XCTAssertNil(SettingsPane.main.backDestination)
    }

    func test_sidebarPanesExposeNativeSettingsSectionsInOrder() {
        XCTAssertEqual(SettingsPane.sidebarPanes, [
            .general,
            .carousel,
            .hiddenApps,
            .about,
        ])
        XCTAssertEqual(SettingsPane.general.titleKey, "settings.general.section")
        XCTAssertEqual(SettingsPane.carousel.systemImage, "rectangle.stack")
        XCTAssertEqual(SettingsPane.hiddenApps.systemImage, "eye.slash")
        XCTAssertEqual(SettingsPane.about.titleKey, "settings.about.section")
    }
}
