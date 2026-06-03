import XCTest

final class LocalizationTests: XCTestCase {

    func test_appBundleIncludesEnglishAndKoreanLocalizations() throws {
        let localizations = Set(Bundle.main.localizations)

        XCTAssertTrue(localizations.contains("en"))
        XCTAssertTrue(localizations.contains("ko"))
    }

    func test_koreanLocalizationProvidesCoreUserFacingStrings() throws {
        let bundle = try localizationBundle(for: "ko")

        XCTAssertEqual(bundle.localizedString(forKey: "settings.window.title", value: nil, table: nil), "Lathe - 환경설정")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.appearance.language", value: nil, table: nil), "언어")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.carousel.showAppNames", value: nil, table: nil), "앱 이름 표시")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.hiddenApps.add", value: nil, table: nil), "앱 추가...")
        XCTAssertEqual(bundle.localizedString(forKey: "menu.preferences", value: nil, table: nil), "환경설정...")
    }

    func test_englishLocalizationProvidesCoreUserFacingStrings() throws {
        let bundle = try localizationBundle(for: "en")

        XCTAssertEqual(bundle.localizedString(forKey: "settings.window.title", value: nil, table: nil), "Lathe - Preferences")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.appearance.language", value: nil, table: nil), "Language")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.carousel.showAppNames", value: nil, table: nil), "Show app names")
        XCTAssertEqual(bundle.localizedString(forKey: "settings.hiddenApps.add", value: nil, table: nil), "Add App...")
        XCTAssertEqual(bundle.localizedString(forKey: "menu.preferences", value: nil, table: nil), "Preferences...")
    }

    private func localizationBundle(for identifier: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: identifier, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }
}
