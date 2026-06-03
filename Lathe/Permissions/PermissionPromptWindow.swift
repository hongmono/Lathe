import AppKit
import SwiftUI

@MainActor
final class PermissionPromptWindow {
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = L10n.string("permission.window.title")
        w.center()
        w.isReleasedWhenClosed = false

        w.titlebarAppearsTransparent = true
        w.backgroundColor = .clear
        w.isMovableByWindowBackground = true

        let host = NSHostingView(rootView: PermissionPromptView { [weak self] in
            self?.openSettings()
        })
        w.contentView = host

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    @objc private func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        AccessibilityChecker.requestTrust()
    }
}
