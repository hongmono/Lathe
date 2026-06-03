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
            w.title = L10n.string("settings.window.title")
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        let host = NSHostingController(rootView: SettingsView(store: .shared))
        let w = NSWindow(contentViewController: host)
        w.title = L10n.string("settings.window.title")
        w.styleMask = [.titled, .closable]
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
                self?.window?.title = L10n.string("settings.window.title")
            }
            .store(in: &cancellables)
    }
}
