import Foundation

enum LayoutStyle: String, CaseIterable, Identifiable {
    case fan
    case strip
    case stack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fan: L10n.string("layout.fan")
        case .strip: L10n.string("layout.strip")
        case .stack: L10n.string("layout.stack")
        }
    }
}
