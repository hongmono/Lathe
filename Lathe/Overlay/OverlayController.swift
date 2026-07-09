import AppKit
import SwiftUI

struct OverlaySelection {
    let app: AppEntry
    let window: WindowEntry?
}

@MainActor
final class OverlayController {
    private let panel = OverlayPanel()
    private let carouselViewModel = CarouselViewModel()
    private let windowFocusTracker = WindowFocusTracker()
    private lazy var windowSelectionViewModel = WindowSelectionViewModel(focusTracker: windowFocusTracker)
    private(set) var isVisible = false

    /// 카드 클릭 시 선택 확정(활성화+닫기). AppDelegate가 설정한다.
    var onCommit: (() -> Void)?

    init() {
        let rootView = OverlayRootView(
            carouselViewModel: carouselViewModel,
            windowSelectionViewModel: windowSelectionViewModel
        )
        let host = FirstMouseHostingView(rootView: rootView)
        host.onClick = { [weak self] point in self?.handleClick(at: point) }
        host.onHover = { [weak self] point in self?.handleHover(at: point) }
        host.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            host.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        panel.contentView = container
    }

    func show(apps: [AppEntry], initialIndex: Int) {
        carouselViewModel.update(apps: apps, selectedIndex: initialIndex)
        reloadWindowsForCurrentApp()
        guard !apps.isEmpty else { return }
        positionAtActiveScreenCenter()
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 1
        }
        isVisible = true
    }

    func updateApps(_ apps: [AppEntry]) {
        carouselViewModel.replaceApps(apps)
        reloadWindowsForCurrentApp()
    }

    func next() {
        carouselViewModel.next()
        reloadWindowsForCurrentApp()
    }

    func previous() {
        carouselViewModel.previous()
        reloadWindowsForCurrentApp()
    }

    /// 카드 클릭: 해당 앱을 선택하고 창목록을 갱신한 뒤 곧바로 확정한다.
    func pick(app: AppEntry) {
        guard let idx = carouselViewModel.apps.firstIndex(where: { $0.id == app.id }) else { return }
        carouselViewModel.select(idx)
        reloadWindowsForCurrentApp()
        onCommit?()
    }

    /// 히트테스트: OverlayRootView와 동일한 지오메트리로 카드 프레임을 재구성해 앱 인덱스를 찾는다.
    /// 회전은 무시(근사) — 앞(zIndex 큰) 카드부터 검사한다.
    private func appIndex(at point: NSPoint) -> Int? {
        let settings = SettingsStore.shared
        let cardWidth = CGFloat(settings.cardSize)
        let cardHeight = cardWidth * 1.36            // OverlayRootView.heightRatio
        let pivotDistance = cardWidth * 2.9          // OverlayRootView.pivotRatio
        let frameSide = (pivotDistance + cardHeight) * 2
        let cx = frameSide / 2, cy = frameSide / 2

        let items = CarouselLayout.items(
            appCount: carouselViewModel.apps.count,
            selectedIndex: carouselViewModel.selectedIndex,
            style: settings.layoutStyle,
            angularStep: settings.angularStep,
            fanRadius: settings.fanRadius,
            fanSpacing: settings.fanSpacing,
            maxVisibleEachSide: CarouselGeometry.maxVisibleEachSide(for: settings.layoutStyle)
        )
        return items.sorted { $0.zIndex > $1.zIndex }.first { item in
            let s = CGFloat(item.scale)
            let w = cardWidth * s, h = cardHeight * s
            let rect = CGRect(x: cx + CGFloat(item.offsetX) - w / 2,
                              y: cy + CGFloat(item.offsetY) - h / 2,
                              width: w, height: h)
            return rect.contains(point)
        }?.index
    }

    /// 카드 클릭: 그 앱으로 전환.
    private func handleClick(at point: NSPoint) {
        if let idx = appIndex(at: point), carouselViewModel.apps.indices.contains(idx) {
            pick(app: carouselViewModel.apps[idx])
        }
    }

    /// hover: 그 위 카드의 dim 제거 + 커서를 포인팅 핸드로(패널은 mouseEntered에서 key가 됨).
    private func handleHover(at point: NSPoint?) {
        let idx = point.flatMap { appIndex(at: $0) }
        let id = idx.flatMap { carouselViewModel.apps.indices.contains($0) ? carouselViewModel.apps[$0].id : nil }
        carouselViewModel.setHovered(id)
        (id != nil ? NSCursor.pointingHand : NSCursor.arrow).set()
    }

    func cycleWindow() {
        windowSelectionViewModel.next()
    }

    func cycleWindowPrevious() {
        windowSelectionViewModel.previous()
    }

    func currentSelection() -> OverlaySelection? {
        guard let app = carouselViewModel.currentEntry else { return nil }
        let window = windowSelectionViewModel.hasMultipleWindows
            ? windowSelectionViewModel.currentWindow
            : nil
        return OverlaySelection(app: app, window: window)
    }

    func recordWindowActivation() {
        windowSelectionViewModel.recordActivation()
    }

    func hide(animated: Bool) {
        guard isVisible else { return }
        isVisible = false
        carouselViewModel.setHovered(nil)
        NSCursor.arrow.set()
        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.15
                panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    self?.panel.orderOut(nil)
                }
            })
        } else {
            panel.alphaValue = 0
            panel.orderOut(nil)
        }
    }

    private func reloadWindowsForCurrentApp() {
        windowSelectionViewModel.load(forProcessIdentifier: carouselViewModel.currentEntry?.id)
    }

    private func positionAtActiveScreenCenter() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first!
        let frame = panel.frame
        let originX = screen.frame.midX - frame.width / 2
        let originY = screen.frame.midY - frame.height / 2
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
}
