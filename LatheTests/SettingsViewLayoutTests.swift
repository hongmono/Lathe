import XCTest
@testable import Lathe

final class SettingsViewLayoutTests: XCTestCase {

    func test_settingsContentUsesStableTopSpacing() {
        XCTAssertLessThanOrEqual(SettingsViewLayout.detailTopMargin, 32)
    }

    func test_settingsWindowKeepsPermanentSidebarCardInset() {
        XCTAssertGreaterThan(SettingsViewLayout.sidebarOuterPadding, 0)
        XCTAssertLessThanOrEqual(SettingsViewLayout.sidebarOuterPadding, 16)
    }

    func test_settingsSectionsUseCardLikeGlassShape() {
        XCTAssertGreaterThanOrEqual(SettingsViewLayout.sectionCornerRadius, 16)
    }

    func test_settingsDetailSurfaceUsesVisibleBrightnessOverlay() {
        XCTAssertGreaterThan(SettingsViewLayout.detailSurfaceOverlayOpacity, 0)
        XCTAssertLessThanOrEqual(SettingsViewLayout.detailSurfaceOverlayOpacity, 0.12)
    }
}
