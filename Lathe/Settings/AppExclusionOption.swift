struct AppExclusionOption: Identifiable, Equatable {
    let bundleIdentifier: String
    let name: String

    var id: String { bundleIdentifier }

    static func options(from apps: [AppEntry],
                        excludedBundleIdentifiers: Set<String>) -> [AppExclusionOption] {
        var namesByBundleIdentifier: [String: String] = [:]

        for app in apps {
            guard let bundleIdentifier = app.bundleIdentifier else { continue }
            if namesByBundleIdentifier[bundleIdentifier] == nil {
                namesByBundleIdentifier[bundleIdentifier] = app.name
            }
        }

        for bundleIdentifier in excludedBundleIdentifiers {
            if namesByBundleIdentifier[bundleIdentifier] == nil {
                namesByBundleIdentifier[bundleIdentifier] = bundleIdentifier
            }
        }

        return namesByBundleIdentifier
            .map { AppExclusionOption(bundleIdentifier: $0.key, name: $0.value) }
            .sorted {
                let nameOrder = $0.name.localizedStandardCompare($1.name)
                if nameOrder == .orderedSame {
                    return $0.bundleIdentifier < $1.bundleIdentifier
                }
                return nameOrder == .orderedAscending
            }
    }
}
