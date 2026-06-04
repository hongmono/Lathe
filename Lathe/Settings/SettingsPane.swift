enum SettingsPane: Equatable, Hashable, Identifiable {
    case main
    case general
    case permissions
    case carousel
    case hiddenApps
    case about

    var id: Self { self }

    static let sidebarPanes: [SettingsPane] = [
        .general,
        .permissions,
        .carousel,
        .hiddenApps,
        .about,
    ]

    var titleKey: String {
        switch self {
        case .main:
            return "settings.window.title"
        case .general:
            return "settings.general.section"
        case .permissions:
            return "settings.permissions.section"
        case .carousel:
            return "settings.carousel.section"
        case .hiddenApps:
            return "settings.hiddenApps.section"
        case .about:
            return "settings.about.section"
        }
    }

    var systemImage: String {
        switch self {
        case .main:
            return "gearshape"
        case .general:
            return "gearshape"
        case .permissions:
            return "hand.raised"
        case .carousel:
            return "rectangle.stack"
        case .hiddenApps:
            return "eye.slash"
        case .about:
            return "info.circle"
        }
    }

    var backDestination: SettingsPane? {
        switch self {
        case .main, .general, .permissions, .carousel, .about:
            return nil
        case .hiddenApps:
            return .main
        }
    }
}
