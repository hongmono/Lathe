import SwiftUI
import AppKit

final class SettingsNavigationState: ObservableObject {
    @Published var selectedPane: SettingsPane?

    init(selectedPane: SettingsPane? = .general) {
        self.selectedPane = selectedPane
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var navigation: SettingsNavigationState

    // 설정창은 사이드바가 곧 내비게이션이므로 항상 펼친 상태로 잠근다.
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init(store: SettingsStore,
         navigation: SettingsNavigationState = SettingsNavigationState()) {
        self.store = store
        self.navigation = navigation
    }

    private var selectedPane: SettingsPane {
        navigation.selectedPane ?? .general
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SettingsSidebarView(store: store, selectedPane: $navigation.selectedPane)
                .navigationSplitViewColumnWidth(
                    min: SettingsViewLayout.sidebarMinWidth,
                    ideal: SettingsViewLayout.sidebarWidth,
                    max: SettingsViewLayout.sidebarMaxWidth
                )
                .toolbar(removing: .sidebarToggle)
        } detail: {
            SettingsDetailView(store: store, pane: selectedPane)
                .background(Color(nsColor: .windowBackgroundColor))
                .navigationTitle(L10n.string(selectedPane.titleKey, language: store.appLanguage))
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: SettingsViewLayout.windowMinWidth,
            minHeight: SettingsViewLayout.windowMinHeight
        )
    }
}

enum SettingsViewLayout {
    static let windowMinWidth: CGFloat = 680
    static let windowMinHeight: CGFloat = 560
    static let sidebarMinWidth: CGFloat = 180
    static let sidebarWidth: CGFloat = 200
    static let sidebarMaxWidth: CGFloat = 320
    static let detailHorizontalPadding: CGFloat = 24
    static let detailTopMargin: CGFloat = 24
    static let detailMaxWidth: CGFloat = 620
    static let sectionSpacing: CGFloat = 16
    static let detailGroupSpacing: CGFloat = 8
    static let detailRowSpacing: CGFloat = 12
    static let detailBottomPadding: CGFloat = 24
    static let detailSectionBreakHeight: CGFloat = 24
}

#if DEBUG
#Preview("Settings") {
    SettingsView(store: SettingsPreviewStore.makeStore())
        .frame(
            width: SettingsWindowChromeConfiguration.sidebarIntegrated.initialSize.width,
            height: SettingsWindowChromeConfiguration.sidebarIntegrated.initialSize.height
        )
}
#endif
