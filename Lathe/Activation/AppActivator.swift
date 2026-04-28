import AppKit

enum AppActivator {
    static func activate(_ entry: AppEntry) {
        guard let app = NSRunningApplication(processIdentifier: entry.id) else { return }
        app.activate()
    }
}
