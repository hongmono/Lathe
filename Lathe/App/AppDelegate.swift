import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var hotKey: HotKeyMonitor!
    private var appList: AppListProvider!
    private var overlay: OverlayController!
    private let settingsWindow = SettingsWindowController()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        SettingsStore.shared.applyAppearance()

        let updater = SparkleUpdater.shared
        menuBar = MenuBarController()
        menuBar.onCheckForUpdates = {
            updater.checkForUpdates()
        }
        menuBar.onShowPermissions = { [weak self] in
            self?.settingsWindow.show(pane: .permissions)
        }
        menuBar.onShowPreferences = { [weak self] in
            self?.settingsWindow.show()
        }
        updater.$canCheckForUpdates
            .sink { [weak self] canCheckForUpdates in
                self?.menuBar.setCanCheckForUpdates(canCheckForUpdates)
            }
            .store(in: &cancellables)

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
            settingsWindow.show(pane: .permissions)
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
        hideOverlay(animated: true)
    }

    func hotKeyDidRequestNext() {
        if overlay.isVisible {
            overlay.next()
        } else {
            appList.refresh()
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            let initial = apps.count > 1 ? 1 : 0
            overlay.show(apps: apps, initialIndex: initial)
            hotKey.arrowsEnabled = overlay.isVisible
        }
    }

    func hotKeyDidRequestPrevious() {
        if overlay.isVisible {
            overlay.previous()
        } else {
            appList.refresh()
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            overlay.show(apps: apps, initialIndex: apps.count - 1)
            hotKey.arrowsEnabled = overlay.isVisible
        }
    }

    func hotKeyDidCancel() {
        hideOverlay(animated: true)
    }

    private func hideOverlay(animated: Bool) {
        hotKey.arrowsEnabled = false
        overlay.hide(animated: animated)
    }
}
