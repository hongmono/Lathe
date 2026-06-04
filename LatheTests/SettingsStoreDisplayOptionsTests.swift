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
    func test_fanRadiusDefaultsToConfiguredDefault() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.fanRadius, SettingsStore.defaultFanRadius)
    }

    @MainActor
    func test_fanRadiusPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.fanRadius = 720

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.fanRadius, 720)
    }

    @MainActor
    func test_fanRadiusIgnoresLegacyDegreeValues() {
        let defaults = makeDefaults()
        defaults.set(13.0, forKey: "fanRadius")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.fanRadius, SettingsStore.defaultFanRadius)
    }

    @MainActor
    func test_fanRadiusClampsPersistedOutOfRangeValues() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.fanRadius = 2_000

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.fanRadius, CarouselGeometry.fanRadiusRange.upperBound)
    }

    @MainActor
    func test_fanSpacingDefaultsToConfiguredDefault() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.fanSpacing, SettingsStore.defaultFanSpacing)
    }

    @MainActor
    func test_fanSpacingPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.fanSpacing = 150

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.fanSpacing, 150)
    }

    @MainActor
    func test_fanSpacingClampsPersistedOutOfRangeValues() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.fanSpacing = 440

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.fanSpacing, CarouselGeometry.fanSpacingRange.upperBound)
    }

    @MainActor
    func test_resetCarouselDefaultsShowsAppNames() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.showAppNamesInCarousel = false

        store.resetCarouselDefaults()

        XCTAssertTrue(store.showAppNamesInCarousel)
    }

    @MainActor
    func test_resetCarouselDefaultsRestoresFanRadius() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.fanRadius = 720

        store.resetCarouselDefaults()

        XCTAssertEqual(store.fanRadius, SettingsStore.defaultFanRadius)
    }

    @MainActor
    func test_resetCarouselDefaultsRestoresFanSpacing() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.fanSpacing = 150

        store.resetCarouselDefaults()

        XCTAssertEqual(store.fanSpacing, SettingsStore.defaultFanSpacing)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
