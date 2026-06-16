import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKeyMonitor!
    private var appList: AppListProvider!
    private var overlay: OverlayController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 전용 앱: Dock 아이콘을 띄우지 않는다.
        NSApp.setActivationPolicy(.accessory)

        SettingsStore.shared.applyAppearance()

        // Sparkle 업데이터 기동(메뉴는 SparkleUpdater.shared를 직접 관찰).
        _ = SparkleUpdater.shared

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
            AppState.shared.permissionGranted = true
        } catch {
            AppState.shared.permissionGranted = false
            SettingsWindowController.shared.show(pane: .permissions)
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
