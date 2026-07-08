import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKeyMonitor!
    private var appList: AppListProvider!
    private var overlay: OverlayController!
    private var missionControl: MissionControlController!

    private var isMissionControl: Bool { SettingsStore.shared.layoutMode == .missionControl }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 전용 앱: Dock 아이콘을 띄우지 않는다.
        NSApp.setActivationPolicy(.accessory)

        SettingsStore.shared.applyAppearance()

        // Sparkle 업데이터 기동(메뉴는 SparkleUpdater.shared를 직접 관찰).
        _ = SparkleUpdater.shared

        appList = AppListProvider()
        overlay = OverlayController()
        missionControl = MissionControlController()
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
            // cmd+` 는 오버레이 표시 여부와 무관하게 전역에서 윈도우 전환 진입점으로 사용한다.
            hotKey.windowCycleEnabled = true
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
        // 어느 쪽이 떠 있든 그 컨트롤러의 선택을 활성화한다.
        let presenter: OverlayPresenting? =
            overlay.isVisible ? overlay : (missionControl.isVisible ? missionControl : nil)
        guard let presenter else { return }
        if let selection = presenter.currentSelection() {
            presenter.recordWindowActivation()
            AppActivator.activate(selection.app, window: selection.window)
        }
        hideOverlay(animated: true)
    }

    func hotKeyDidRequestNext() {
        if isMissionControl {
            if missionControl.isVisible { missionControl.next() }
            else { presentMissionControl(forward: true) }
            return
        }
        if overlay.isVisible {
            overlay.next()
        } else {
            appList.refresh()
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            let initial = apps.count > 1 ? 1 : 0
            overlay.show(apps: apps, initialIndex: initial)
            updateHotKeyModes()
        }
    }

    func hotKeyDidRequestPrevious() {
        if isMissionControl {
            if missionControl.isVisible { missionControl.previous() }
            else { presentMissionControl(forward: false) }
            return
        }
        if overlay.isVisible {
            overlay.previous()
        } else {
            appList.refresh()
            let apps = appList.apps
            guard !apps.isEmpty else { return }
            overlay.show(apps: apps, initialIndex: apps.count - 1)
            updateHotKeyModes()
        }
    }

    func hotKeyDidRequestCycleWindow() {
        if isMissionControl {
            if missionControl.isVisible { missionControl.next() }
            else { presentMissionControl(forward: true) }
            return
        }
        if overlay.isVisible {
            overlay.cycleWindow()
        } else {
            beginWindowSwitch(forward: true)
        }
    }

    func hotKeyDidRequestCycleWindowPrevious() {
        if isMissionControl {
            if missionControl.isVisible { missionControl.previous() }
            else { presentMissionControl(forward: false) }
            return
        }
        if overlay.isVisible {
            overlay.cycleWindowPrevious()
        } else {
            beginWindowSwitch(forward: false)
        }
    }

    /// 미션 컨트롤 오버레이를 첫 표시한다.
    private func presentMissionControl(forward: Bool) {
        appList.refresh()
        let apps = appList.apps
        guard !apps.isEmpty else { return }
        missionControl.show(appEntries: apps, forward: forward)
        updateHotKeyModes()
    }

    func hotKeyDidCancel() {
        hideOverlay(animated: true)
    }

    /// cmd+` 단독 입력 시 최전면 앱을 선택한 채 오버레이를 띄우고 곧바로 윈도우를 한 칸 이동한다.
    private func beginWindowSwitch(forward: Bool) {
        appList.refresh()
        let apps = appList.apps
        guard !apps.isEmpty else { return }

        let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let initial = frontPID.flatMap { pid in apps.firstIndex(where: { $0.id == pid }) } ?? 0
        overlay.show(apps: apps, initialIndex: initial)
        updateHotKeyModes()

        if forward {
            overlay.cycleWindow()
        } else {
            overlay.cycleWindowPrevious()
        }
    }

    private func hideOverlay(animated: Bool) {
        hotKey.arrowsEnabled = false
        if overlay.isVisible { overlay.hide(animated: animated) }
        if missionControl.isVisible { missionControl.hide(animated: animated) }
    }

    private func updateHotKeyModes() {
        hotKey.arrowsEnabled = overlay.isVisible || missionControl.isVisible
    }
}
