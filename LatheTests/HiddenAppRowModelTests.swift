import XCTest
@testable import Lathe

final class HiddenAppRowModelTests: XCTestCase {

    func test_rowsReflectCurrentHiddenStateForManagedApps() {
        let options = [
            AppExclusionOption(bundleIdentifier: "com.example.editor", name: "Editor", icon: nil),
            AppExclusionOption(bundleIdentifier: "com.example.browser", name: "Browser", icon: nil),
        ]

        let rows = HiddenAppRowModel.rows(
            from: options,
            excludedBundleIdentifiers: ["com.example.browser"]
        )

        XCTAssertEqual(rows.map(\.bundleIdentifier), [
            "com.example.editor",
            "com.example.browser",
        ])
        XCTAssertEqual(rows.map(\.isHidden), [
            false,
            true,
        ])
    }
}
