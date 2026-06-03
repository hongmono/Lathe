import AppKit
import XCTest
@testable import Lathe

final class AppExclusionOptionTests: XCTestCase {

    func test_optionsIncludeRunningAppsAndExcludedBundleIdentifiers() {
        let apps = [
            AppEntry(id: 1, bundleIdentifier: "com.example.alpha", name: "Alpha", icon: NSImage()),
            AppEntry(id: 2, bundleIdentifier: nil, name: "Unbundled", icon: NSImage()),
            AppEntry(id: 3, bundleIdentifier: "com.example.beta", name: "Beta", icon: NSImage()),
            AppEntry(id: 4, bundleIdentifier: "com.example.alpha", name: "Alpha Copy", icon: NSImage()),
        ]

        let options = AppExclusionOption.options(
            from: apps,
            excludedBundleIdentifiers: ["com.example.beta", "com.example.hidden"]
        )

        XCTAssertEqual(options.map(\.bundleIdentifier), [
            "com.example.alpha",
            "com.example.beta",
            "com.example.hidden",
        ])
        XCTAssertEqual(options.map(\.name), [
            "Alpha",
            "Beta",
            "com.example.hidden",
        ])
    }

    func test_optionsUseInstalledMetadataForExcludedAppsThatAreNotRunning() {
        let installedApps = [
            AppBundleMetadata(bundleIdentifier: "com.example.hidden", name: "Hidden App", icon: NSImage())
        ]

        let options = AppExclusionOption.options(
            from: [],
            excludedBundleIdentifiers: ["com.example.hidden"],
            installedApps: installedApps
        )

        XCTAssertEqual(options.map(\.bundleIdentifier), ["com.example.hidden"])
        XCTAssertEqual(options.map(\.name), ["Hidden App"])
    }

    func test_appBundleMetadataReadsBundleIdentifierAndDisplayNameFromApplicationURL() throws {
        let appURL = try makeApplicationBundle(
            bundleIdentifier: "com.example.selected",
            displayName: "Selected App"
        )

        let metadata = try XCTUnwrap(AppBundleMetadata.metadata(applicationURL: appURL))

        XCTAssertEqual(metadata.bundleIdentifier, "com.example.selected")
        XCTAssertEqual(metadata.name, "Selected App")
    }

    private func makeApplicationBundle(bundleIdentifier: String, displayName: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LatheTests.\(UUID().uuidString)", isDirectory: true)
        let contentsURL = root
            .appendingPathComponent("Selected.app", isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let infoPlist: [String: String] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleDisplayName": displayName,
            "CFBundleName": "Fallback Name",
            "CFBundlePackageType": "APPL",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))

        return root.appendingPathComponent("Selected.app", isDirectory: true)
    }
}
