enum SettingsPane: Equatable {
    case main
    case hiddenApps

    var backDestination: SettingsPane? {
        switch self {
        case .main:
            return nil
        case .hiddenApps:
            return .main
        }
    }
}
