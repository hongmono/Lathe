import AppKit

struct SettingsWindowChromeConfiguration {
    let styleMask: NSWindow.StyleMask
    let titleVisibility: NSWindow.TitleVisibility
    let titlebarAppearsTransparent: Bool
    let toolbarStyle: NSWindow.ToolbarStyle
    let collectionBehavior: NSWindow.CollectionBehavior
    let isMovableByWindowBackground: Bool

    static let sidebarIntegrated = SettingsWindowChromeConfiguration(
        styleMask: [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView,
        ],
        titleVisibility: .hidden,
        titlebarAppearsTransparent: true,
        toolbarStyle: .unified,
        collectionBehavior: [.fullScreenPrimary],
        isMovableByWindowBackground: true
    )

    @MainActor
    func apply(to window: NSWindow) {
        window.styleMask = styleMask
        window.titleVisibility = titleVisibility
        window.titlebarAppearsTransparent = titlebarAppearsTransparent
        window.toolbarStyle = toolbarStyle
        window.collectionBehavior.formUnion(collectionBehavior)
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = isMovableByWindowBackground
    }
}
