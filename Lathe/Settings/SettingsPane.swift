enum SettingsPane: Equatable, Hashable, Identifiable {
    case main
    case general
    case carousel
    case hiddenApps
    case about

    var id: Self { self }

    static let sidebarPanes: [SettingsPane] = [
        .general,
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
        case .main, .general, .carousel, .about:
            return nil
        case .hiddenApps:
            return .main
        }
    }
}
