import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    init() {
        observeLanguage()
    }

    func show() {
        if let w = window {
            updateWindowTitle(w)
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        let configuration = SettingsWindowChromeConfiguration.sidebarIntegrated
        let host = NSHostingController(rootView: SettingsView(store: .shared))
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: configuration.initialSize),
            styleMask: configuration.styleMask,
            backing: .buffered,
            defer: false
        )
        w.contentViewController = host
        updateWindowTitle(w)
        configuration.apply(to: w)
        w.isReleasedWhenClosed = false
        w.center()
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        window = w
    }

    private func observeLanguage() {
        SettingsStore.shared.$appLanguage
            .dropFirst()
            .sink { [weak self] _ in
                guard let window = self?.window else { return }
                self?.updateWindowTitle(window)
            }
            .store(in: &cancellables)
    }

    private func updateWindowTitle(_ window: NSWindow) {
        window.title = ""
        window.setAccessibilityTitle(L10n.string("settings.window.title", language: SettingsStore.shared.appLanguage))
    }
}
