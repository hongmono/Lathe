import XCTest
@testable import Lathe

final class SettingsStoreLayoutModeTests: XCTestCase {

    @MainActor
    func test_defaultsToCarousel() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.layoutMode, .carousel)
    }

    @MainActor
    func test_persistsLayoutMode() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.layoutMode = .missionControl

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.layoutMode, .missionControl)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
