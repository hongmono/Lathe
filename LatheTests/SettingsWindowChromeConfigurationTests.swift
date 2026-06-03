import AppKit
import XCTest
@testable import Lathe

final class SettingsWindowChromeConfigurationTests: XCTestCase {

    func test_settingsWindowUsesSidebarIntegratedTitlebarChrome() {
        let configuration = SettingsWindowChromeConfiguration.sidebarIntegrated

        XCTAssertTrue(configuration.styleMask.contains(.titled))
        XCTAssertTrue(configuration.styleMask.contains(.closable))
        XCTAssertTrue(configuration.styleMask.contains(.miniaturizable))
        XCTAssertTrue(configuration.styleMask.contains(.resizable))
        XCTAssertTrue(configuration.styleMask.contains(.fullSizeContentView))
        XCTAssertEqual(configuration.titleVisibility, .hidden)
        XCTAssertTrue(configuration.titlebarAppearsTransparent)
        XCTAssertEqual(configuration.titlebarSeparatorStyle, .none)
        XCTAssertEqual(configuration.toolbarStyle, .unified)
        XCTAssertTrue(configuration.collectionBehavior.contains(.fullScreenPrimary))
        XCTAssertEqual(configuration.initialSize.width, 680)
        XCTAssertEqual(configuration.initialSize.height, 560)
        XCTAssertEqual(configuration.minimumSize.width, 680)
        XCTAssertEqual(configuration.minimumSize.height, 560)
    }
}
