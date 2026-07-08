import AppKit
import SwiftUI

@MainActor
final class MissionControlController {
    private var panels: [OverlayPanel] = []
    private let viewModel = MissionControlViewModel()
    private let provider = MissionControlWindowProvider()
    private let thumbnails = WindowThumbnailProvider()
    private(set) var isVisible = false
    private var didRequestScreenRecording = false

    /// 현재 Space 창을 열거해 각 모니터 패널에 펼친다. forward=true면 활성창 다음을 선택.
    func show(appEntries: [AppEntry], forward: Bool) {
        let windows = provider.windows(appEntries: appEntries)
        guard !windows.isEmpty else { return }

        let activeWindowID = frontmostWindowID(in: windows)
        viewModel.set(windows: windows, selectedWindowID: activeWindowID)
        if forward { viewModel.next() } else { viewModel.previous() }

        rebuildPanels()
        for panel in panels {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panels.forEach { $0.animator().alphaValue = 1 }
        }
        isVisible = true

        // 썸네일 비동기 캡처 → 완료되는 대로 채운다.
        let ids = windows.map(\.id)
        Task { [weak self] in
            guard let self else { return }
            // 권한이 아직 없으면 최초 1회 시스템 프롬프트를 띄우고 목록에 등록한다.
            // (허용 후 앱 재시작하면 다음부터 실제 썸네일이 채워진다.)
            guard WindowThumbnailProvider.hasPermission() else {
                // 권한 없으면 앱 실행 중 최초 1회만 프롬프트(매번 나그 방지). 이후엔 설정에서 처리.
                if !self.didRequestScreenRecording {
                    self.didRequestScreenRecording = true
                    WindowThumbnailProvider.requestPermission()
                }
                return
            }
            let images = await self.thumbnails.capture(windowIDs: ids)
            for (id, image) in images { self.viewModel.setThumbnail(image, forWindowID: id) }
        }
    }

    func next() { viewModel.next() }
    func previous() { viewModel.previous() }

    func currentSelection() -> OverlaySelection? {
        guard let window = viewModel.currentWindow else { return nil }
        return OverlaySelection(app: window.appEntry, window: window.windowEntry)
    }

    func recordWindowActivation() { /* MC는 창 단위 MRU 기록 없음. no-op. */ }

    func hide(animated: Bool) {
        guard isVisible else { return }
        isVisible = false
        let toClose = panels
        panels = []
        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.15
                toClose.forEach { $0.animator().alphaValue = 0 }
            }, completionHandler: {
                MainActor.assumeIsolated { toClose.forEach { $0.orderOut(nil) } }
            })
        } else {
            toClose.forEach {
                $0.alphaValue = 0
                $0.orderOut(nil)
            }
        }
    }

    /// 화면 수만큼 패널을 만들어 각 화면을 꽉 채운다.
    private func rebuildPanels() {
        panels.forEach { $0.orderOut(nil) }
        panels = NSScreen.screens.enumerated().map { index, screen in
            let panel = OverlayPanel()
            panel.setFrame(screen.frame, display: true)
            let root = MissionControlScreenView(viewModel: viewModel,
                                                screenIndex: index,
                                                areaSize: screen.frame.size)
            let host = NSHostingView(rootView: root)
            host.frame = NSRect(origin: .zero, size: screen.frame.size)
            host.autoresizingMask = [.width, .height]
            let container = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            container.addSubview(host)
            panel.contentView = container
            return panel
        }
    }

    private func frontmostWindowID(in windows: [MCWindow]) -> Int? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return windows.first?.id
        }
        return windows.first(where: { $0.pid == pid })?.id ?? windows.first?.id
    }
}
