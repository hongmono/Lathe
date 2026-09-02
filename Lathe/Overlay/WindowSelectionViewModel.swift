import Foundation
import Combine

enum WindowSelectionItem: Identifiable, Equatable {
    enum ID: Hashable {
        case window(Int)
        case browserTab(String)
    }

    case window(WindowEntry)
    case browserTab(BrowserTabEntry)

    var id: ID {
        switch self {
        case .window(let window):
            return .window(window.id)
        case .browserTab(let tab):
            return .browserTab(tab.id)
        }
    }
}

@MainActor
final class WindowSelectionViewModel: ObservableObject {
    @Published private(set) var windows: [WindowEntry] = []
    @Published private(set) var items: [WindowSelectionItem] = []
    @Published private(set) var selectedIndex: Int = 0

    private let focusTracker: WindowFocusTracker
    private let browserTabProvider: any BrowserTabProviding
    private let browserTabsEnabled: () -> Bool
    private var currentProcessIdentifier: pid_t?

    init(focusTracker: WindowFocusTracker,
         browserTabProvider: any BrowserTabProviding = AccessibilityBrowserTabProvider(),
         browserTabsEnabled: @escaping () -> Bool = { SettingsStore.shared.showBrowserTabsInCarousel }) {
        self.focusTracker = focusTracker
        self.browserTabProvider = browserTabProvider
        self.browserTabsEnabled = browserTabsEnabled
    }

    var hasMultipleWindows: Bool {
        windows.count > 1
    }

    var hasMultipleItems: Bool {
        items.count > 1
    }

    var currentWindow: WindowEntry? {
        guard items.indices.contains(selectedIndex) else { return nil }
        switch items[selectedIndex] {
        case .window(let window):
            return window
        case .browserTab(let tab):
            return tab.window
        }
    }

    var currentBrowserTab: BrowserTabEntry? {
        guard items.indices.contains(selectedIndex),
              case .browserTab(let tab) = items[selectedIndex] else {
            return nil
        }
        return tab
    }

    func load(forProcessIdentifier pid: pid_t?) {
        currentProcessIdentifier = pid
        guard let pid else {
            windows = []
            items = []
            selectedIndex = 0
            return
        }

        let entries = focusTracker.windows(forProcessIdentifier: pid)
        windows = entries

        if browserTabsEnabled() {
            let tabs = browserTabProvider.tabs(forProcessIdentifier: pid, windows: entries)
            if tabs.count > 1 {
                items = tabs.map(WindowSelectionItem.browserTab)
                selectedIndex = tabs.firstIndex(where: \.isSelected) ?? 0
                return
            }
        }

        items = entries.map(WindowSelectionItem.window)
        selectedIndex = focusTracker.preferredIndex(for: entries, processIdentifier: pid)
    }

    func next() {
        guard items.count > 1 else { return }
        selectedIndex = (selectedIndex + 1) % items.count
    }

    func previous() {
        guard items.count > 1 else { return }
        selectedIndex = (selectedIndex - 1 + items.count) % items.count
    }

    func prepareSelectionForActivation() {
        guard let tab = currentBrowserTab else { return }
        browserTabProvider.activate(tab: tab)
    }

    func recordActivation() {
        touchCurrentSelection()
    }

    private func touchCurrentSelection() {
        guard let pid = currentProcessIdentifier, let window = currentWindow else { return }
        focusTracker.touchSelectedWindow(window, processIdentifier: pid)
    }
}
