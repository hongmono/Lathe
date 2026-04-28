import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    private let panel = OverlayPanel()
    private let viewModel = CarouselViewModel()
    private(set) var isVisible = false

    init() {
        let host = NSHostingView(rootView: CarouselView(viewModel: viewModel))
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
        viewModel.update(apps: apps, selectedIndex: initialIndex)
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
        viewModel.replaceApps(apps)
    }

    func next() { viewModel.next() }
    func previous() { viewModel.previous() }

    func currentSelection() -> AppEntry? {
        viewModel.currentEntry
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
