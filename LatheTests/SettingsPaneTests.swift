import XCTest
@testable import Lathe

final class SettingsPaneTests: XCTestCase {

    func test_hiddenAppsPaneReturnsToMainSettingsPane() {
        XCTAssertEqual(SettingsPane.hiddenApps.backDestination, .main)
        XCTAssertNil(SettingsPane.main.backDestination)
    }
}
