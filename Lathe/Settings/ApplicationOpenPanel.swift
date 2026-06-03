import AppKit
import UniformTypeIdentifiers

enum ApplicationOpenPanel {
    @MainActor
    static func make(title: String) -> NSOpenPanel {
        let panel = NSOpenPanel()
        configure(panel, title: title)
        return panel
    }

    @MainActor
    static func configure(_ panel: NSOpenPanel, title: String) {
        panel.title = title
        panel.prompt = title
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
    }
}
