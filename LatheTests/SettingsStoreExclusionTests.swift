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

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
