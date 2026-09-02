import XCTest
@testable import Lathe

final class BrowserTabProviderTests: XCTestCase {
    func test_supportedBrowserBundleIdentifiers() {
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "at.studio.AsideBrowser"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.apple.Safari"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.google.Chrome"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.brave.Browser"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.microsoft.edgemac"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.vivaldi.Vivaldi"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "company.thebrowser.Browser"))
        XCTAssertTrue(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "org.mozilla.firefox"))
    }

    func test_nonBrowserBundleIdentifierIsNotSupported() {
        XCTAssertFalse(AccessibilityBrowserTabProvider.supports(bundleIdentifier: "com.apple.finder"))
        XCTAssertFalse(AccessibilityBrowserTabProvider.supports(bundleIdentifier: nil))
    }
}
