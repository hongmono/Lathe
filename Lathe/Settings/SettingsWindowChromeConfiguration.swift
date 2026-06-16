import AppKit

struct SettingsWindowChromeConfiguration {
    let styleMask: NSWindow.StyleMask
    let titleVisibility: NSWindow.TitleVisibility
    let titlebarAppearsTransparent: Bool
    let titlebarSeparatorStyle: NSTitlebarSeparatorStyle
    let toolbarStyle: NSWindow.ToolbarStyle
    let collectionBehavior: NSWindow.CollectionBehavior
    let isMovableByWindowBackground: Bool
    let initialSize: NSSize
    let minimumSize: NSSize
    let toolbarIdentifier: NSToolbar.Identifier

    private static let defaultSize = NSSize(
        width: SettingsViewLayout.windowMinWidth,
        height: SettingsViewLayout.windowMinHeight
    )

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
        titlebarSeparatorStyle: .none,
        toolbarStyle: .unified,
        collectionBehavior: [.fullScreenPrimary],
        isMovableByWindowBackground: false,
        initialSize: defaultSize,
        minimumSize: defaultSize,
        toolbarIdentifier: "LatheSettingsToolbar"
    )

    @MainActor
    func apply(to window: NSWindow) {
        window.styleMask = styleMask
        window.titleVisibility = titleVisibility
        window.titlebarAppearsTransparent = titlebarAppearsTransparent
        window.titlebarSeparatorStyle = titlebarSeparatorStyle
        window.toolbarStyle = toolbarStyle
        window.collectionBehavior.formUnion(collectionBehavior)
        window.isMovableByWindowBackground = isMovableByWindowBackground
        window.minSize = minimumSize
        window.toolbar = makeToolbar()
    }

    @MainActor
    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: toolbarIdentifier)
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = false
        toolbar.isVisible = true
        return toolbar
    }
}
