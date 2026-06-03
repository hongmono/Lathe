import SwiftUI
import AppKit

struct SettingsSidebarView: View {
    @ObservedObject var store: SettingsStore
    @Binding var selectedPane: SettingsPane?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SettingsViewLayout.sidebarContentTopPadding)
            
            List(selection: $selectedPane) {
                ForEach(SettingsPane.sidebarPanes) { pane in
                    Label(L10n.string(pane.titleKey, language: store.appLanguage), systemImage: pane.systemImage)
                        .tag(Optional(pane))
                    
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer(minLength: 0)
        }
    }
}

#if DEBUG
#Preview("Settings Sidebar") {
    SettingsSidebarView(
        store: SettingsPreviewStore.makeStore(),
        selectedPane: .constant(.general)
    )
        .frame(
            width: SettingsViewLayout.sidebarWidth,
            height: SettingsViewLayout.windowMinHeight
        )
        .padding(SettingsViewLayout.sidebarOuterPadding)
        .background(.ultraThinMaterial)
}
#endif
