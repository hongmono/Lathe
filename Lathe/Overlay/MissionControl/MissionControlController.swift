import AppKit
import SwiftUI

@MainActor
final class MissionControlController {
    private var panels: [OverlayPanel] = []
    private let viewModel = MissionControlViewModel()
    private let provider = MissionControlWindowProvider()
    private let thumbnails = WindowThumbnailProvider()
    private let focusTracker = WindowFocusTracker()   // 앱별 창 MRU 순서
    private(set) var isVisible = false
    private var didRequestScreenRecording = false

    /// 타일 클릭 시 선택 확정(활성화+닫기). AppDelegate가 설정한다.
    var onCommit: (() -> Void)?

    init() {
        viewModel.onCommit = { [weak self] in self?.onCommit?() }
    }

    /// 현재 Space 창을 앱별 스택으로 묶어 각 모니터 패널에 펼친다. forward=true면 활성 앱 다음 스택을 선택.
    func show(appEntries: [AppEntry], forward: Bool) {
        let builtStacks = stacks(appEntries: appEntries)
        guard !builtStacks.isEmpty else { return }

        let activeWindowID = frontmostWindowID(inStacks: builtStacks)
        viewModel.set(stacks: builtStacks, selectedWindowID: activeWindowID)
        if forward { viewModel.next() } else { viewModel.previous() }

        rebuildPanels()
        for panel in panels {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        // 마우스가 있는 화면의 패널을 key로 → 클릭 이벤트가 확실히 그 패널로 오도록.
        let mouse = NSEvent.mouseLocation
        let keyIdx = NSScreen.screens.firstIndex { NSMouseInRect(mouse, $0.frame, false) } ?? 0
        if panels.indices.contains(keyIdx) { panels[keyIdx].makeKey() }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panels.forEach { $0.animator().alphaValue = 1 }
        }
        isVisible = true

        // 썸네일 비동기 캡처 → 완료되는 대로 채운다. (모든 스택의 모든 창)
        let ids = builtStacks.flatMap { $0.windows.map(\.id) }
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
            self.viewModel.setThumbnails(images)
        }
    }

    func next() { viewModel.next() }
    func previous() { viewModel.previous() }

    /// ⌘+`: 선택된 앱 스택 안에서 창 순환.
    func cycleWindow() { viewModel.cycleWindow() }
    func cycleWindowPrevious() { viewModel.cycleWindowPrevious() }

    func currentSelection() -> OverlaySelection? {
        guard let window = viewModel.currentWindow else { return nil }
        return OverlaySelection(app: window.appEntry, window: window.windowEntry)
    }

    func recordWindowActivation() {
        guard let window = viewModel.currentWindow else { return }
        focusTracker.touchSelectedWindow(window.windowEntry, processIdentifier: window.pid)
    }

    func hide(animated: Bool) {
        guard isVisible else { return }
        isVisible = false
        viewModel.setHovered(nil)
        NSCursor.arrow.set()
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

    /// 화면-로컬 좌표에서 그 위 스택 id를 찾는다. 뷰와 동일한 tiles() 계산 재사용 → 위치 정확히 일치.
    private func stackID(at point: NSPoint, screenIndex: Int) -> Int? {
        guard NSScreen.screens.indices.contains(screenIndex) else { return nil }
        let areaSize = NSScreen.screens[screenIndex].frame.size
        let mine = viewModel.stacks.filter { $0.screenIndex == screenIndex }
        let tiles = MissionControlLayout.tiles(
            windows: mine.map { (id: $0.id, frame: $0.frontWindow.localFrame) },
            in: CGRect(origin: .zero, size: areaSize)
        )
        return tiles.first(where: { $0.rect.contains(point) })?.windowID   // tile.windowID == stack.id
    }

    /// 타일 클릭: 그 스택으로 전환.
    private func handleClick(at point: NSPoint, screenIndex: Int) {
        if let id = stackID(at: point, screenIndex: screenIndex) { viewModel.pick(stackID: id) }
    }

    /// hover: 그 위 타일의 dim 제거 + 커서를 포인팅 핸드로(패널은 mouseEntered에서 key가 됨).
    private func handleHover(at point: NSPoint?, screenIndex: Int) {
        let id = point.flatMap { stackID(at: $0, screenIndex: screenIndex) }
        viewModel.setHovered(id)
        (id != nil ? NSCursor.pointingHand : NSCursor.arrow).set()
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
            let host = FirstMouseHostingView(rootView: root)
            host.frame = NSRect(origin: .zero, size: screen.frame.size)
            host.autoresizingMask = [.width, .height]
            host.onClick = { [weak self] point in self?.handleClick(at: point, screenIndex: index) }
            host.onHover = { [weak self] point in self?.handleHover(at: point, screenIndex: index) }
            let container = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            container.addSubview(host)
            panel.contentView = container
            return panel
        }
    }

    /// 창을 앱별 MRU 순으로 정렬한 뒤 (앱, 화면) 스택으로 묶는다.
    private func stacks(appEntries: [AppEntry]) -> [MCAppStack] {
        let raw = provider.windows(appEntries: appEntries)

        // pid별로 모아 등장 순서를 유지.
        var byPID: [pid_t: [MCWindow]] = [:]
        var pidOrder: [pid_t] = []
        for window in raw {
            if byPID[window.pid] == nil { pidOrder.append(window.pid) }
            byPID[window.pid, default: []].append(window)
        }

        // 각 앱의 창을 MRU(포커스 트래커) 순위로 정렬.
        var ordered: [MCWindow] = []
        for pid in pidOrder {
            let mruIDs = focusTracker.windows(forProcessIdentifier: pid).map(\.id)
            let rank = Dictionary(uniqueKeysWithValues: mruIDs.enumerated().map { ($1, $0) })
            let sorted = (byPID[pid] ?? []).enumerated().sorted {
                let a = rank[$0.element.id] ?? Int.max
                let b = rank[$1.element.id] ?? Int.max
                return a != b ? a < b : $0.offset < $1.offset
            }.map(\.element)
            ordered.append(contentsOf: sorted)
        }

        return MissionControlWindowProvider.group(ordered)
    }

    private func frontmostWindowID(inStacks stacks: [MCAppStack]) -> Int? {
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
           let stack = stacks.first(where: { $0.appEntry.id == pid }) {
            return stack.frontWindow.id
        }
        return stacks.first?.frontWindow.id
    }
}
