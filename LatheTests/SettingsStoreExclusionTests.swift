import XCTest
@testable import Lathe

final class SettingsStoreExclusionTests: XCTestCase {

    @MainActor
    func test_setExcludedBundleIdentifierPersistsAndReloads() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.setExcluded(true, bundleIdentifier: "com.example.browser")
        store.setExcluded(true, bundleIdentifier: "com.apple.finder")

        XCTAssertEqual(store.excludedBundleIdentifiers, [
            "com.apple.finder",
            "com.example.browser",
        ])

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.excludedBundleIdentifiers, store.excludedBundleIdentifiers)
    }

    @MainActor
    func test_setExcludedFalseRemovesBundleIdentifier() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.setExcluded(true, bundleIdentifier: "com.apple.finder")
        store.setExcluded(false, bundleIdentifier: "com.apple.finder")

        XCTAssertFalse(store.isExcluded(bundleIdentifier: "com.apple.finder"))
    }

    @MainActor
    func test_addHiddenAppPersistsListAndExcludesByDefault() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.addHiddenApp(bundleIdentifier: "com.example.browser")

        XCTAssertEqual(store.hiddenAppBundleIdentifiers, ["com.example.browser"])
        XCTAssertTrue(store.isExcluded(bundleIdentifier: "com.example.browser"))

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.hiddenAppBundleIdentifiers, ["com.example.browser"])
        XCTAssertTrue(reloaded.isExcluded(bundleIdentifier: "com.example.browser"))
    }

    @MainActor
    func test_togglingHiddenAppOffKeepsItInHiddenAppList() {
        let store = SettingsStore(userDefaults: makeDefaults())

        store.addHiddenApp(bundleIdentifier: "com.example.browser")
        store.setExcluded(false, bundleIdentifier: "com.example.browser")

        XCTAssertEqual(store.hiddenAppBundleIdentifiers, ["com.example.browser"])
        XCTAssertFalse(store.isExcluded(bundleIdentifier: "com.example.browser"))
    }

    @MainActor
    func test_removeHiddenAppsRemovesThemFromListAndExclusions() {
        let store = SettingsStore(userDefaults: makeDefaults())

        store.addHiddenApp(bundleIdentifier: "com.example.browser")
        store.addHiddenApp(bundleIdentifier: "com.example.editor")

        store.removeHiddenApps(bundleIdentifiers: ["com.example.browser"])

        XCTAssertEqual(store.hiddenAppBundleIdentifiers, ["com.example.editor"])
        XCTAssertFalse(store.isExcluded(bundleIdentifier: "com.example.browser"))
        XCTAssertTrue(store.isExcluded(bundleIdentifier: "com.example.editor"))
    }

    @MainActor
    func test_existingExcludedAppsSeedHiddenAppList() {
        let defaults = makeDefaults()
        defaults.set(["com.example.legacy"], forKey: "excludedBundleIdentifiers")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.hiddenAppBundleIdentifiers, ["com.example.legacy"])
        XCTAssertTrue(store.isExcluded(bundleIdentifier: "com.example.legacy"))

        store.setExcluded(false, bundleIdentifier: "com.example.legacy")

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.hiddenAppBundleIdentifiers, ["com.example.legacy"])
        XCTAssertFalse(reloaded.isExcluded(bundleIdentifier: "com.example.legacy"))
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
