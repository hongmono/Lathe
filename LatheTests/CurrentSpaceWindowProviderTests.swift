import CoreGraphics
import XCTest
@testable import Lathe

final class CurrentSpaceWindowProviderTests: XCTestCase {

    func test_processIdentifiersUsesOnlyNormalLayerWindows() {
        let ownerPIDKey = kCGWindowOwnerPID as String
        let layerKey = kCGWindowLayer as String
        let windows: [[String: Any]] = [
            [ownerPIDKey: NSNumber(value: Int32(101)), layerKey: NSNumber(value: 0)],
            [ownerPIDKey: NSNumber(value: Int32(202)), layerKey: NSNumber(value: 8)],
            [ownerPIDKey: NSNumber(value: Int32(-1)), layerKey: NSNumber(value: 0)],
            [layerKey: NSNumber(value: 0)],
        ]

        XCTAssertEqual(
            CurrentSpaceWindowProvider.processIdentifiers(fromWindowList: windows),
            Set<pid_t>([101])
        )
    }
}
