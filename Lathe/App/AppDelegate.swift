import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var hotKey: HotKeyMonitor!
    private var appList: AppListProvider!
    private var overlay: OverlayController!
    private let permissionWindow = PermissionPromptWindow()
    private let settingsWindow = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        SettingsStore.shared.applyAppearance()

        menuBar = MenuBarController()
        menuBar.onShowPermissions = { [weak self] in
            self?.permissionWindow.show()
        }
        menuBar.onShowPreferences = { [weak self] in
            self?.settingsWindow.show()
        }

        appList = AppListProvider()
        overlay = OverlayController()
        appList.didChange = { [weak self] in
            guard let self else { return }
            if self.overlay.isVisible {
                self.overlay.updateApps(self.appList.apps)
            }
        }

        hotKey = HotKeyMonitor()
        hotKey.delegate = self

        do {
            try hotKey.start()
            menuBar.setPermissionStatus(granted: true)
        } catch {
            menuBar.setPermissionStatus(granted: false)
            permissionWindow.show()
        }
    }
}

extension AppDelegate: HotKeyMonitorDelegate {
    func hotKeyDidArm() {
        // Pre-arm: nothing visible yet.
    }

    func hotKeyDidDisarm() {
        guard overlay.isVisible else { return }
        if let entry = overlay.currentSelection() {
            AppActivator.activate(entry)
        }
        overlay.hide(animated: true)
    }

    func hotKeyDidRequestNext() {
        if overlay.isVisible {
            overlay.next()
        } else {
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            let initial = apps.count > 1 ? 1 : 0
            overlay.show(apps: apps, initialIndex: initial)
        }
    }

    func hotKeyDidRequestPrevious() {
        if overlay.isVisible {
            overlay.previous()
        } else {
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            overlay.show(apps: apps, initialIndex: apps.count - 1)
        }
    }

    func hotKeyDidCancel() {
        overlay.hide(animated: true)
    }
}
