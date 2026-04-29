import Foundation

enum LayoutStyle: String, CaseIterable, Identifiable {
    case fan
    case strip
    case stack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fan: "Fan"
        case .strip: "Strip"
        case .stack: "Stack"
        }
    }
}
