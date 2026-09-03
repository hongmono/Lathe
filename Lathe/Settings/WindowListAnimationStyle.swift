import Foundation

enum WindowListAnimationStyle: String, CaseIterable, Identifiable {
    case whole
    case staggered
    case expand

    var id: String { rawValue }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .whole:
            L10n.string("windowListAnimation.whole", language: displayLanguage)
        case .staggered:
            L10n.string("windowListAnimation.staggered", language: displayLanguage)
        case .expand:
            L10n.string("windowListAnimation.expand", language: displayLanguage)
        }
    }
}
