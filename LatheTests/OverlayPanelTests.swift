import AppKit
import XCTest
@testable import Lathe

final class OverlayPanelTests: XCTestCase {

    @MainActor
    func test_overlayPanelCanJoinFullScreenApplicationSpaces() {
        let panel = OverlayPanel()

        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllApplications))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }
}
