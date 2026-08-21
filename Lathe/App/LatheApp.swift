import SwiftUI
import AppKit

@main
struct LatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isMenuBarExtraInserted = MenuBarInsertionPolicy.initialValue

    var body: some Scene {
        // 설정창은 AppKit NSSplitViewController(SettingsWindowController)로 띄운다.
        // 메뉴바만 SwiftUI 씬으로 둔다.
        MenuBarExtra(isInserted: menuBarExtraInsertion) {
            MenuBarContent()
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }

    private var menuBarExtraInsertion: Binding<Bool> {
        Binding(
            get: { isMenuBarExtraInserted },
            set: { isMenuBarExtraInserted = MenuBarInsertionPolicy.resolve($0) }
        )
    }
}

enum MenuBarInsertionPolicy {
    static let initialValue = true

    static func resolve(_: Bool) -> Bool {
        true
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var permissionGranted = true
    let navigation = SettingsNavigationState()

    /// 권한 부여를 감지해 핫키 재설치를 시도하는 훅(AppDelegate가 주입).
    var onRetryPermission: (() -> Void)?

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
