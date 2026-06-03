import XCTest
@testable import Lathe

final class SettingsStoreDisplayOptionsTests: XCTestCase {

    @MainActor
    func test_showAppNamesInCarouselDefaultsToTrue() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertTrue(store.showAppNamesInCarousel)
    }

    @MainActor
    func test_showAppNamesInCarouselPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.showAppNamesInCarousel = false

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertFalse(reloaded.showAppNamesInCarousel)
    }

    @MainActor
    func test_resetCarouselDefaultsShowsAppNames() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.showAppNamesInCarousel = false

        store.resetCarouselDefaults()

        XCTAssertTrue(store.showAppNamesInCarousel)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
