import AppKit

struct AppBundleMetadata: Equatable {
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?

    static func resolve(bundleIdentifier: String) -> AppBundleMetadata? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return metadata(applicationURL: url) ?? metadata(bundleIdentifier: bundleIdentifier, applicationURL: url)
    }

    static func metadata(applicationURL: URL) -> AppBundleMetadata? {
        guard let bundle = Bundle(url: applicationURL),
              let bundleIdentifier = bundle.bundleIdentifier,
              !bundleIdentifier.isEmpty else {
            return nil
        }
        return metadata(bundleIdentifier: bundleIdentifier, applicationURL: applicationURL)
    }

    static func metadata(bundleIdentifier: String, applicationURL: URL) -> AppBundleMetadata {
        let bundle = Bundle(url: applicationURL)
        let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
        let fallbackName = applicationURL.deletingPathExtension().lastPathComponent
        return AppBundleMetadata(
            bundleIdentifier: bundleIdentifier,
            name: displayName ?? bundleName ?? fallbackName,
            icon: NSWorkspace.shared.icon(forFile: applicationURL.path)
        )
    }
}

struct AppExclusionOption: Identifiable, Equatable {
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?

    var id: String { bundleIdentifier }

    static func options(from apps: [AppEntry],
                        excludedBundleIdentifiers: Set<String>,
                        installedApps: [AppBundleMetadata] = []) -> [AppExclusionOption] {
        var optionsByBundleIdentifier: [String: AppExclusionOption] = [:]

        for app in apps {
            guard let bundleIdentifier = app.bundleIdentifier else { continue }
            if optionsByBundleIdentifier[bundleIdentifier] == nil {
                optionsByBundleIdentifier[bundleIdentifier] = AppExclusionOption(
                    bundleIdentifier: bundleIdentifier,
                    name: app.name,
                    icon: app.icon
                )
            }
        }

        for app in installedApps {
            if optionsByBundleIdentifier[app.bundleIdentifier] == nil {
                optionsByBundleIdentifier[app.bundleIdentifier] = AppExclusionOption(
                    bundleIdentifier: app.bundleIdentifier,
                    name: app.name,
                    icon: app.icon
                )
            }
        }

        for bundleIdentifier in excludedBundleIdentifiers {
            if optionsByBundleIdentifier[bundleIdentifier] == nil {
                optionsByBundleIdentifier[bundleIdentifier] = AppExclusionOption(
                    bundleIdentifier: bundleIdentifier,
                    name: bundleIdentifier,
                    icon: nil
                )
            }
        }

        return Array(optionsByBundleIdentifier.values)
            .sorted {
                let nameOrder = $0.name.localizedStandardCompare($1.name)
                if nameOrder == .orderedSame {
                    return $0.bundleIdentifier < $1.bundleIdentifier
                }
                return nameOrder == .orderedAscending
            }
    }

    static func == (lhs: AppExclusionOption, rhs: AppExclusionOption) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.name == rhs.name
    }
}
