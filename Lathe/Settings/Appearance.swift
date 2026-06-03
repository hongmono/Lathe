import AppKit

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .system: return L10n.string("appearance.matchSystem", language: displayLanguage)
        case .light:  return L10n.string("appearance.light", language: displayLanguage)
        case .dark:   return L10n.string("appearance.dark", language: displayLanguage)
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }
}
