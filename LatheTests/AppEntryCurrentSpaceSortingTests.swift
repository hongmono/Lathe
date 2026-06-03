import AppKit
import XCTest
@testable import Lathe

final class AppEntryCurrentSpaceSortingTests: XCTestCase {

    func test_prioritizingCurrentSpaceMovesMatchingAppsFirstWithoutChangingGroupOrder() {
        let apps = [
            AppEntry(id: 10, bundleIdentifier: "com.example.mail", name: "Mail", icon: NSImage()),
            AppEntry(id: 20, bundleIdentifier: "com.example.browser", name: "Browser", icon: NSImage()),
            AppEntry(id: 30, bundleIdentifier: "com.example.editor", name: "Editor", icon: NSImage()),
            AppEntry(id: 40, bundleIdentifier: "com.example.chat", name: "Chat", icon: NSImage()),
        ]

        let prioritized = AppEntry.prioritizingCurrentSpace(
            apps,
            currentSpaceProcessIdentifiers: [20, 40]
        )

        XCTAssertEqual(prioritized.map(\.id), [20, 40, 10, 30])
    }
}
