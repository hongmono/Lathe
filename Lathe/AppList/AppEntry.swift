import AppKit

struct AppEntry: Identifiable, Equatable {
    let id: pid_t
    let bundleIdentifier: String?
    let name: String
    let icon: NSImage
    let isCurrentSpace: Bool

    init(id: pid_t,
         bundleIdentifier: String?,
         name: String,
         icon: NSImage,
         isCurrentSpace: Bool = false) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.icon = icon
        self.isCurrentSpace = isCurrentSpace
    }

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

    static func prioritizingCurrentSpace(_ apps: [AppEntry],
                                         currentSpaceProcessIdentifiers pids: Set<pid_t>) -> [AppEntry] {
        guard !pids.isEmpty else { return apps }

        let currentSpaceApps = apps.filter { pids.contains($0.id) }
        let otherApps = apps.filter { !pids.contains($0.id) }
        return currentSpaceApps + otherApps
    }
}
