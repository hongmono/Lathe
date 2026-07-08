import Foundation

enum LayoutMode: String, CaseIterable, Identifiable {
    case carousel
    case missionControl

    var id: String { rawValue }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .carousel: L10n.string("layout.mode.carousel", language: displayLanguage)
        case .missionControl: L10n.string("layout.mode.missionControl", language: displayLanguage)
        }
    }
}
