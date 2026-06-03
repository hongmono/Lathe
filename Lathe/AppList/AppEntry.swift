import AppKit

struct AppEntry: Identifiable, Equatable {
    let id: pid_t
    let bundleIdentifier: String?
    let name: String
    let icon: NSImage

    static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
        lhs.id == rhs.id
    }

    static func visibleInCarousel(_ apps: [AppEntry],
                                  excludingBundleIdentifiers excluded: Set<String>) -> [AppEntry] {
        apps.filter { entry in
            guard let bundleIdentifier = entry.bundleIdentifier else { return true }
            return !excluded.contains(bundleIdentifier)
        }
    }
}
