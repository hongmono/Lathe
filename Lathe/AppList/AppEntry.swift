import AppKit

struct AppEntry: Identifiable, Equatable {
    let id: pid_t
    let bundleIdentifier: String?
    let name: String
    let icon: NSImage

    static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
        lhs.id == rhs.id
    }
}
