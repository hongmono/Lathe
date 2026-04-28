import AppKit

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    var onShowPermissions: () -> Void = {}
    var onShowPreferences: () -> Void = {}

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: "Lathe")
            button.image?.isTemplate = true
        }
        rebuildMenu()
    }

    func setPermissionStatus(granted: Bool) {
        rebuildMenu(granted: granted)
    }

    private func rebuildMenu(granted: Bool = true) {
        let menu = NSMenu()
        let header = NSMenuItem(
            title: granted ? "Lathe — running" : "Lathe — needs permission",
            action: nil,
            keyEquivalent: ""
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let prefs = NSMenuItem(title: "Preferences…",
                               action: #selector(showPreferences),
                               keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let perm = NSMenuItem(title: "Permissions…",
                              action: #selector(showPermissions),
                              keyEquivalent: "")
        perm.target = self
        menu.addItem(perm)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Lathe",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func showPermissions() {
        onShowPermissions()
    }

    @objc private func showPreferences() {
        onShowPreferences()
    }
}
