import XCTest
@testable import Lathe

final class AppLanguageTests: XCTestCase {

    @MainActor
    func test_appLanguageDefaultsToSystem() {
        let store = SettingsStore(userDefaults: makeDefaults())

        XCTAssertEqual(store.appLanguage, .system)
    }

    @MainActor
    func test_appLanguagePersistsAndReloads() {
        let defaults = makeDefaults()
        let store = SettingsStore(userDefaults: defaults)

        store.appLanguage = .korean

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.appLanguage, .korean)
    }

    func test_l10nUsesExplicitLanguageBundle() {
        XCTAssertEqual(
            L10n.string("settings.window.title", language: .english),
            "Lathe - Preferences"
        )
        XCTAssertEqual(
            L10n.string("settings.window.title", language: .korean),
            "Lathe - 환경설정"
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
