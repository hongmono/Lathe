import AppKit
import Combine
import SwiftUI

/// 설정창을 AppKit NSSplitViewController로 구성한다. 사이드바/디테일은 SwiftUI를
/// NSHostingController로 호스팅하되, 분할/토글은 AppKit이 담당한다. 툴바의
/// toggleSidebar + sidebarTrackingSeparator 덕분에 메일/Finder처럼 토글이 매끄럽다.
@MainActor
final class SettingsWindowController: NSObject, NSToolbarDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    private var navigation: SettingsNavigationState { AppState.shared.navigation }

    private override init() {
        super.init()
    }

    func show(pane: SettingsPane = .general) {
        navigation.selectedPane = pane

        let window = window ?? makeWindow()
        if self.window == nil {
            self.window = window
            window.center()
        }
        updateTitle()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let split = NSSplitViewController()

        let sidebarHost = NSHostingController(
            rootView: SettingsSidebarView(
                store: .shared,
                selectedPane: Binding(
                    get: { AppState.shared.navigation.selectedPane },
                    set: { AppState.shared.navigation.selectedPane = $0 }
                )
            )
        )
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarHost)
        sidebarItem.minimumThickness = SettingsViewLayout.sidebarMinWidth
        sidebarItem.maximumThickness = SettingsViewLayout.sidebarMaxWidth
        sidebarItem.canCollapse = true

        let detailHost = NSHostingController(rootView: SettingsDetailHost())
        let detailItem = NSSplitViewItem(viewController: detailHost)
        detailItem.minimumThickness = SettingsViewLayout.detailMinWidth

        split.addSplitViewItem(sidebarItem)
        split.addSplitViewItem(detailItem)

        let window = NSWindow(contentViewController: split)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(
            width: SettingsViewLayout.windowMinWidth,
            height: SettingsViewLayout.windowMinHeight
        ))
        window.minSize = NSSize(
            width: SettingsViewLayout.windowMinWidth,
            height: SettingsViewLayout.windowMinHeight
        )
        window.collectionBehavior.formUnion(.fullScreenPrimary)

        let toolbar = NSToolbar(identifier: "LatheSettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar

        observeForTitle()
        return window
    }

    private func observeForTitle() {
        navigation.$selectedPane
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
        SettingsStore.shared.$appLanguage
            .dropFirst()
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
    }

    private func updateTitle() {
        let pane = navigation.selectedPane ?? .general
        window?.title = L10n.string(pane.titleKey, language: SettingsStore.shared.appLanguage)
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        // 사용하는 항목(toggleSidebar / sidebarTrackingSeparator / flexibleSpace)은
        // 모두 시스템이 자동 제공한다.
        nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        // 추적 구분자 앞(사이드바 쪽)에 flexibleSpace를 둬서 토글 버튼을 사이드바
        // 영역의 오른쪽 끝에 붙인다.
        [.flexibleSpace, .toggleSidebar, .sidebarTrackingSeparator]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .toggleSidebar, .sidebarTrackingSeparator]
    }
}

/// 디테일 패널: 선택된 pane을 관찰해 SwiftUI 콘텐츠를 갱신한다.
private struct SettingsDetailHost: View {
    @ObservedObject private var navigation = AppState.shared.navigation
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        SettingsDetailView(store: store, pane: navigation.selectedPane ?? .general)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(sidebarToggleShortcut)
    }

    // Cmd+B → 네이티브 toggleSidebar:를 responder chain으로 전달. Cmd+키는
    // key equivalent라 SwiftUI keyboardShortcut(=performKeyEquivalent 경로)로 받아야 한다.
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
