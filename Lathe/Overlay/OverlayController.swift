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

    init() {
        let rootView = OverlayRootView(
            carouselViewModel: carouselViewModel,
            windowSelectionViewModel: windowSelectionViewModel
        )
        let host = NSHostingView(rootView: rootView)
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
