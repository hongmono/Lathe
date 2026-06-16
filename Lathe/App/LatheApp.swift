import SwiftUI
import AppKit

@main
struct LatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 설정창은 AppKit NSSplitViewController(SettingsWindowController)로 띄운다.
        // 메뉴바만 SwiftUI 씬으로 둔다.
        MenuBarExtra {
            MenuBarContent()
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var permissionGranted = true
    let navigation = SettingsNavigationState()

    private init() {}
}

private struct MenuBarContent: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var updater = SparkleUpdater.shared

    var body: some View {
        Text(appState.permissionGranted
             ? L10n.string("menu.status.running")
             : L10n.string("menu.status.needsPermission"))

        Divider()

        Button(L10n.string("menu.checkForUpdates")) {
            updater.checkForUpdates()
        }
        .disabled(!updater.canCheckForUpdates)

        Button(L10n.string("menu.preferences")) {
            SettingsWindowController.shared.show(pane: .general)
        }
        Button(L10n.string("menu.permissions")) {
            SettingsWindowController.shared.show(pane: .permissions)
        }

        Divider()

        Button(L10n.string("menu.quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
