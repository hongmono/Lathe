import XCTest
@testable import Lathe

final class SettingsViewLayoutTests: XCTestCase {

    func test_settingsContentUsesStableTopSpacingWithoutOffsetCorrection() {
        XCTAssertEqual(SettingsViewLayout.detailContentOffsetY, 0)
        XCTAssertLessThanOrEqual(SettingsViewLayout.detailTopMargin, 32)
    }
}
