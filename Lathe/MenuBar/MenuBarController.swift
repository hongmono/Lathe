import AppKit
import Combine

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private var permissionGranted = true
    private var cancellables = Set<AnyCancellable>()
    var onShowPermissions: () -> Void = {}
    var onShowPreferences: () -> Void = {}

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = Self.makeStatusImage()
        }
        rebuildMenu()
        observeLanguage()
    }

    func setPermissionStatus(granted: Bool) {
        permissionGranted = granted
        rebuildMenu()
    }

    private func rebuildMenu() {
        if let button = statusItem.button {
            button.image?.accessibilityDescription = L10n.string("menu.accessibilityDescription")
        }
        let menu = NSMenu()
        let header = NSMenuItem(
            title: permissionGranted ? L10n.string("menu.status.running") : L10n.string("menu.status.needsPermission"),
            action: nil,
            keyEquivalent: ""
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let prefs = NSMenuItem(title: L10n.string("menu.preferences"),
                               action: #selector(showPreferences),
                               keyEquivalent: "")
        prefs.target = self
        menu.addItem(prefs)

        let perm = NSMenuItem(title: L10n.string("menu.permissions"),
                              action: #selector(showPermissions),
                              keyEquivalent: "")
        perm.target = self
        menu.addItem(perm)

        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.string("menu.quit"),
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func observeLanguage() {
        SettingsStore.shared.$appLanguage
            .dropFirst()
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    @objc private func showPermissions() {
        onShowPermissions()
    }

    @objc private func showPreferences() {
        onShowPreferences()
    }

    private static func makeStatusImage() -> NSImage? {
        let image = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "circle.dotted",
                       accessibilityDescription: L10n.string("menu.accessibilityDescription"))
        image?.isTemplate = true
        image?.accessibilityDescription = L10n.string("menu.accessibilityDescription")
        return image
    }
}
