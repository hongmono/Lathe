import Foundation

enum LayoutStyle: String, CaseIterable, Identifiable {
    case fan
    case strip
    case stack
    case space

    var id: String { rawValue }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .fan: L10n.string("layout.fan", language: displayLanguage)
        case .strip: L10n.string("layout.strip", language: displayLanguage)
        case .stack: L10n.string("layout.stack", language: displayLanguage)
        case .space: L10n.string("layout.space", language: displayLanguage)
        }
    }
}
