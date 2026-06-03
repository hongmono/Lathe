import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        string(key, language: currentLanguage())
    }

    static func string(_ key: String, language: AppLanguage) -> String {
        guard let bundle = bundle(for: language) else {
            return NSLocalizedString(key, bundle: .main, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static func currentLanguage() -> AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.defaultsKey) ?? "") ?? .system
    }

    private static func bundle(for language: AppLanguage) -> Bundle? {
        guard let identifier = language.localizationIdentifier,
              let path = Bundle.main.path(forResource: identifier, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
}
