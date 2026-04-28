import SwiftUI

@main
struct LatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Pure menu-bar app. Settings window is presented manually
        // via SettingsWindowController; SwiftUI's Settings scene
        // does not reliably activate from an LSUIElement app.
        Settings { EmptyView() }
    }
}
