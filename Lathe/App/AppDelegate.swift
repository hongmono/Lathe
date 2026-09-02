import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKeyMonitor!
    private var appList: AppListProvider!
    private var overlay: OverlayController!
    private var missionControl: MissionControlController!
    private var shouldCommitOnCommandRelease = true

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
        // 카드/타일 클릭도 ⌘ 릴리스와 동일한 확정 경로를 쓴다.
        overlay.onCommit = { [weak self] in self?.commitActiveSelection() }
        missionControl.onCommit = { [weak self] in self?.commitActiveSelection() }
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
        // ⌘ 릴리스 → 현재 선택을 확정.
        if shouldCommitOnCommandRelease {
            commitActiveSelection()
        } else {
            hideOverlay(animated: true)
        }
        shouldCommitOnCommandRelease = true
    }

    private var activePresenter: OverlayPresenting? {
        overlay.isVisible ? overlay : (missionControl.isVisible ? missionControl : nil)
    }

    /// 떠 있는 오버레이의 현재 선택을 활성화하고 닫는다. ⌘ 릴리스와 카드/타일 클릭이 공유한다.
    private func commitActiveSelection() {
        guard let presenter = activePresenter else { return }
        if let selection = presenter.currentSelection() {
            presenter.recordWindowActivation()
            presenter.prepareSelectionForActivation()
            AppActivator.activate(
                selection.app,
                window: selection.window,
                reopensWindowlessApplications: SettingsStore.shared.reopenWindowlessApplications
            )
        }
        hideOverlay(animated: true)
    }

    func hotKeyDidRequestNext() {
        shouldCommitOnCommandRelease = true
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
        shouldCommitOnCommandRelease = true
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
        shouldCommitOnCommandRelease = true
        if isMissionControl {
            if missionControl.isVisible { missionControl.cycleWindow() }
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
        shouldCommitOnCommandRelease = true
        if isMissionControl {
            if missionControl.isVisible { missionControl.cycleWindowPrevious() }
            else { presentMissionControl(forward: false) }
            return
        }
        if overlay.isVisible {
            overlay.cycleWindowPrevious()
        } else {
            beginWindowSwitch(forward: false)
        }
    }

    func hotKeyDidRequestOpenSettings() {
        hideOverlay(animated: false)
        SettingsWindowController.shared.show(pane: .general)
    }

    func hotKeyDidRequestToggleSelectedApplicationHidden() {
        guard let presenter = activePresenter,
              let selection = presenter.currentSelection(),
              let application = NSRunningApplication(processIdentifier: selection.app.id) else {
            return
        }

        // 앱 관리 명령만 실행하고 ⌘을 놓았을 때 선택 앱으로 전환하지 않는다.
        shouldCommitOnCommandRelease = false
        let wasHidden = application.isHidden
        guard AppSwitcherApplicationController.toggleHidden(application) else { return }

        if missionControl.isVisible && !wasHidden {
            // 미션 컨트롤은 현재 보이는 창만 표현하므로 숨긴 앱의 스택을 즉시 걷어낸다.
            presenter.removeApplication(processIdentifier: selection.app.id)
            hideOverlayIfSelectionIsEmpty(presenter)
        } else {
            // 캐러셀에서는 숨긴 앱을 유지하되 상태 아이콘과 흐린 표현을 즉시 갱신한다.
            appList.refresh()
        }
    }

    func hotKeyDidRequestQuitSelectedApplication() {
        guard let presenter = activePresenter,
              let selection = presenter.currentSelection(),
              let application = NSRunningApplication(processIdentifier: selection.app.id) else {
            return
        }

        // 정상 종료 요청만 보낸다. 저장 확인을 건너뛰는 강제 종료는 사용하지 않는다.
        shouldCommitOnCommandRelease = false
        guard AppSwitcherApplicationController.requestTermination(application) else { return }
        presenter.removeApplication(processIdentifier: selection.app.id)
        hideOverlayIfSelectionIsEmpty(presenter)
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
        hotKey.overlayActionsEnabled = false
        if overlay.isVisible { overlay.hide(animated: animated) }
        if missionControl.isVisible { missionControl.hide(animated: animated) }
    }

    private func updateHotKeyModes() {
        hotKey.overlayActionsEnabled = overlay.isVisible || missionControl.isVisible
    }

    private func hideOverlayIfSelectionIsEmpty(_ presenter: OverlayPresenting) {
        if presenter.currentSelection() == nil {
            hideOverlay(animated: true)
        }
    }
}
