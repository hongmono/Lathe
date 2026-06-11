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

    func test_settingOptionLabelsUseExplicitDisplayLanguage() {
        XCTAssertEqual(AppLanguage.system.label(language: .korean), "시스템")
        XCTAssertEqual(AppLanguage.english.label(language: .korean), "영어")
        XCTAssertEqual(AppLanguage.korean.label(language: .korean), "한국어")

        XCTAssertEqual(Appearance.system.label(language: .korean), "시스템 설정 따름")
        XCTAssertEqual(Appearance.light.label(language: .korean), "라이트")
        XCTAssertEqual(Appearance.dark.label(language: .korean), "다크")

        XCTAssertEqual(LayoutStyle.fan.label(language: .korean), "부채꼴")
        XCTAssertEqual(LayoutStyle.strip.label(language: .korean), "가로")
        XCTAssertEqual(LayoutStyle.stack.label(language: .korean), "스택")
        XCTAssertEqual(LayoutStyle.space.label(language: .korean), "공간")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LatheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
