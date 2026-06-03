import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case korean

    static let defaultsKey = "appLanguage"

    var id: String { rawValue }

    var localizationIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .korean:
            return "ko"
        }
    }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .system:
            return L10n.string("language.system", language: displayLanguage)
        case .english:
            return L10n.string("language.english", language: displayLanguage)
        case .korean:
            return L10n.string("language.korean", language: displayLanguage)
        }
    }
}
