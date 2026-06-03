import AppKit
import XCTest
@testable import Lathe

final class AppEntryFilteringTests: XCTestCase {

    func test_visibleInCarouselExcludesAppsByBundleIdentifier() {
        let apps = [
            AppEntry(id: 1, bundleIdentifier: "com.apple.finder", name: "Finder", icon: NSImage()),
            AppEntry(id: 2, bundleIdentifier: nil, name: "Unbundled", icon: NSImage()),
            AppEntry(id: 3, bundleIdentifier: "com.example.browser", name: "Browser", icon: NSImage()),
        ]

        let visible = AppEntry.visibleInCarousel(
            apps,
            excludingBundleIdentifiers: ["com.apple.finder"]
        )

        XCTAssertEqual(visible.map(\.id), [2, 3])
    }
}
