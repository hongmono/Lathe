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

    // Cmd+B로 사이드바를 접고 펼친다. 화면에는 안 보이는 버튼이지만 창 전역
    // 단축키로 동작하며, 표준 사이드바 토글 버튼은 그대로 노출된다.
    private var sidebarToggleShortcut: some View {
        Button(action: toggleSidebar) { Color.clear }
            .buttonStyle(.plain)
            .keyboardShortcut("b", modifiers: .command)
            .opacity(0)
            .accessibilityHidden(true)
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            columnVisibility = (columnVisibility == .detailOnly) ? .all : .detailOnly
        }
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
