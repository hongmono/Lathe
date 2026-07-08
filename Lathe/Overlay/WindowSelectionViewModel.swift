import Foundation
import Combine

@MainActor
final class WindowSelectionViewModel: ObservableObject {
    @Published private(set) var windows: [WindowEntry] = []
    @Published private(set) var selectedIndex: Int = 0

    private let focusTracker: WindowFocusTracker
    private var currentProcessIdentifier: pid_t?

    init(focusTracker: WindowFocusTracker) {
        self.focusTracker = focusTracker
    }

    var hasMultipleWindows: Bool {
        windows.count > 1
    }

    var currentWindow: WindowEntry? {
        guard windows.indices.contains(selectedIndex) else { return nil }
        return windows[selectedIndex]
    }

    func load(forProcessIdentifier pid: pid_t?) {
        currentProcessIdentifier = pid
        guard let pid else {
            windows = []
            selectedIndex = 0
            return
        }

        let entries = focusTracker.windows(forProcessIdentifier: pid)
        windows = entries
        selectedIndex = focusTracker.preferredIndex(for: entries, processIdentifier: pid)
    }

    func next() {
        guard windows.count > 1 else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
        touchCurrentSelection()
    }

    func previous() {
        guard windows.count > 1 else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
        touchCurrentSelection()
    }

    func recordActivation() {
        touchCurrentSelection()
    }

    private func touchCurrentSelection() {
        guard let pid = currentProcessIdentifier, let window = currentWindow else { return }
        focusTracker.touchSelectedWindow(window, processIdentifier: pid)
    }
}
