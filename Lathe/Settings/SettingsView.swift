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

    init(store: SettingsStore,
         navigation: SettingsNavigationState = SettingsNavigationState()) {
        self.store = store
        self.navigation = navigation
    }

    private var selectedPane: SettingsPane {
        navigation.selectedPane ?? .general
    }

    var body: some View {
        NavigationSplitView {
            SettingsSidebarView(store: store, selectedPane: $navigation.selectedPane)
                .navigationSplitViewColumnWidth(
                    min: SettingsViewLayout.sidebarMinWidth,
                    ideal: SettingsViewLayout.sidebarWidth,
                    max: SettingsViewLayout.sidebarMaxWidth
                )
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
        .background(sidebarToggleShortcut)
    }

    // 사이드바 토글은 전적으로 네이티브 경로(NSSplitViewController의 toggleSidebar:)에
    // 맡긴다. 표준 토글 버튼과 동일한 애니메이션을 타므로 reflow 없이 매끄럽다.
    // Cmd+B도 같은 셀렉터를 호출해 일관되게 동작한다.
    private var sidebarToggleShortcut: some View {
        Button {
            NSApp.sendAction(Selector(("toggleSidebar:")), to: nil, from: nil)
        } label: {
            Color.clear
        }
        .buttonStyle(.plain)
        .keyboardShortcut("b", modifiers: .command)
        .opacity(0)
        .accessibilityHidden(true)
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
    static let detailMinWidth: CGFloat = 360
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
