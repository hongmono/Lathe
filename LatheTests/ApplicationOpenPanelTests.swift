import AppKit
import UniformTypeIdentifiers
import XCTest
@testable import Lathe

final class ApplicationOpenPanelTests: XCTestCase {

    @MainActor
    func test_configureAllowsSelectingApplicationBundles() {
        let panel = NSOpenPanel()

        ApplicationOpenPanel.configure(panel, title: "Add App")

        XCTAssertEqual(panel.allowedContentTypes, [.applicationBundle])
        XCTAssertTrue(panel.canChooseFiles)
        XCTAssertFalse(panel.canChooseDirectories)
        XCTAssertFalse(panel.allowsMultipleSelection)
    }
}
