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

        // 새로고침 버튼이 누를 수 있도록 재시도 경로를 공유한다.
        AppState.shared.onRetryPermission = { [weak self] in self?.startHotKeyIfNeeded() }

        if !startHotKeyIfNeeded() {
            SettingsWindowController.shared.show(pane: .permissions)
        }
    }

    // 사용자가 시스템 설정에서 권한을 켜고 앱으로 돌아오면 자동으로 재설치한다.
    func applicationDidBecomeActive(_ notification: Notification) {
        startHotKeyIfNeeded()
    }

    /// 핫키가 아직 설치되지 않았다면 한 번 더 시도한다. 멱등이라 반복 호출해도 안전하다.
    @discardableResult
    private func startHotKeyIfNeeded() -> Bool {
        if hotKey.isRunning { return true }
        do {
            try hotKey.start()
            AppState.shared.permissionGranted = true
            return true
        } catch {
            AppState.shared.permissionGranted = false
            return false
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
