import AppKit

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

        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 12
        container.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: L10n.string("permission.title"))
        title.font = .boldSystemFont(ofSize: 16)

        let body = NSTextField(wrappingLabelWithString: L10n.string("permission.body"))
        body.preferredMaxLayoutWidth = 480

        let button = NSButton(
            title: L10n.string("permission.openSystemSettings"),
            target: self,
            action: #selector(openSettings)
        )
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"

        container.addArrangedSubview(title)
        container.addArrangedSubview(body)
        container.addArrangedSubview(button)

        w.contentView = container
        if let content = w.contentView {
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                container.topAnchor.constraint(equalTo: content.topAnchor),
                container.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            ])
        }

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
