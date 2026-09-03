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
    func test_animateCarouselPresentationDefaultsToTrue() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertTrue(store.animateCarouselPresentation)
    }

    @MainActor
    func test_animateCarouselPresentationPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.animateCarouselPresentation = false

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertFalse(reloaded.animateCarouselPresentation)
    }

    @MainActor
    func test_windowListAnimationStyleDefaultsToStaggered() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.windowListAnimationStyle, .staggered)
    }

    @MainActor
    func test_windowListAnimationStylePersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.windowListAnimationStyle = .expand

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.windowListAnimationStyle, .expand)
    }

    @MainActor
    func test_windowListAnimationStyleFallsBackForUnknownStoredValue() {
        let defaults = makeDefaults()
        defaults.set("unknown", forKey: "windowListAnimationStyle")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.windowListAnimationStyle, .staggered)
    }

    @MainActor
    func test_windowListAnimationSpeedDefaultsToNormal() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.windowListAnimationSpeed, SettingsStore.defaultWindowListAnimationSpeed)
    }

    @MainActor
    func test_windowListAnimationSpeedPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.windowListAnimationSpeed = 1.6

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.windowListAnimationSpeed, 1.6)
    }

    @MainActor
    func test_windowListAnimationSpeedClampsPersistedOutOfRangeValues() {
        let defaults = makeDefaults()
        defaults.set(4.0, forKey: "windowListAnimationSpeed")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.windowListAnimationSpeed, SettingsStore.windowListAnimationSpeedRange.upperBound)
    }

    @MainActor
    func test_windowListAnimationDelayDefaultsToPointThreeSeconds() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.windowListAnimationDelay, 0.3)
    }

    @MainActor
    func test_windowListAnimationDelayPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.windowListAnimationDelay = 0.7

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.windowListAnimationDelay, 0.7)
    }

    @MainActor
    func test_windowListAnimationDelayClampsPersistedOutOfRangeValues() {
        let defaults = makeDefaults()
        defaults.set(2.0, forKey: "windowListAnimationDelay")

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.windowListAnimationDelay, SettingsStore.windowListAnimationDelayRange.upperBound)
    }

    @MainActor
    func test_showBrowserTabsInCarouselDefaultsToFalse() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertFalse(store.showBrowserTabsInCarousel)
    }

    @MainActor
    func test_showBrowserTabsInCarouselPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.showBrowserTabsInCarousel = true

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertTrue(reloaded.showBrowserTabsInCarousel)
    }

    @MainActor
    func test_reopenWindowlessApplicationsDefaultsToTrue() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertTrue(store.reopenWindowlessApplications)
    }

    @MainActor
    func test_reopenWindowlessApplicationsPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.reopenWindowlessApplications = false

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertFalse(reloaded.reopenWindowlessApplications)
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
    func test_resetAnimationDefaultsRestoresPresentationAnimation() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.animateCarouselPresentation = false

        store.resetAnimationDefaults()

        XCTAssertTrue(store.animateCarouselPresentation)
    }

    @MainActor
    func test_resetAnimationDefaultsRestoresWindowListAnimationStyle() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.windowListAnimationStyle = .whole

        store.resetAnimationDefaults()

        XCTAssertEqual(store.windowListAnimationStyle, .staggered)
    }

    @MainActor
    func test_resetAnimationDefaultsRestoresWindowListAnimationSpeed() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.windowListAnimationSpeed = 1.8

        store.resetAnimationDefaults()

        XCTAssertEqual(store.windowListAnimationSpeed, SettingsStore.defaultWindowListAnimationSpeed)
    }

    @MainActor
    func test_resetAnimationDefaultsRestoresWindowListAnimationDelay() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.windowListAnimationDelay = 0.8

        store.resetAnimationDefaults()

        XCTAssertEqual(store.windowListAnimationDelay, SettingsStore.defaultWindowListAnimationDelay)
    }

    @MainActor
    func test_resetCarouselDefaultsDoesNotChangeAnimationPreferences() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.animateCarouselPresentation = false
        store.windowListAnimationStyle = .whole
        store.windowListAnimationSpeed = 1.8
        store.windowListAnimationDelay = 0.8

        store.resetCarouselDefaults()

        XCTAssertFalse(store.animateCarouselPresentation)
        XCTAssertEqual(store.windowListAnimationStyle, .whole)
        XCTAssertEqual(store.windowListAnimationSpeed, 1.8)
        XCTAssertEqual(store.windowListAnimationDelay, 0.8)
    }

    @MainActor
    func test_resetCarouselDefaultsHidesBrowserTabs() {
        let store = SettingsStore(userDefaults: makeDefaults())
        store.showBrowserTabsInCarousel = true

        store.resetCarouselDefaults()

        XCTAssertFalse(store.showBrowserTabsInCarousel)
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
