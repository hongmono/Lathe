import SwiftUI
import AppKit

struct SettingsSidebarView: View {
    @ObservedObject var store: SettingsStore
    @Binding var selectedPane: SettingsPane?

    var body: some View {
        List(selection: $selectedPane) {
            ForEach(SettingsPane.sidebarPanes) { pane in
                Label(L10n.string(pane.titleKey, language: store.appLanguage), systemImage: pane.systemImage)
                    .tag(Optional(pane))
            }
        }
        .listStyle(.sidebar)
    }
}

#if DEBUG
#Preview("Settings Sidebar") {
    NavigationSplitView {
        SettingsSidebarView(
            store: SettingsPreviewStore.makeStore(),
            selectedPane: .constant(.general)
        )
        .navigationSplitViewColumnWidth(
            min: SettingsViewLayout.sidebarMinWidth,
            ideal: SettingsViewLayout.sidebarWidth,
            max: SettingsViewLayout.sidebarMaxWidth
        )
    } detail: {
        Color.clear
    }
    .frame(
        width: SettingsViewLayout.windowMinWidth,
        height: SettingsViewLayout.windowMinHeight
    )
}
#endif
