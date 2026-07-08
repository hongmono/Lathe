import AppKit
import Combine

@MainActor
final class MissionControlViewModel: ObservableObject {
    @Published private(set) var windows: [MCWindow] = []
    @Published private(set) var selectedIndex: Int = 0
    @Published private(set) var thumbnails: [Int: NSImage] = [:]

    func set(windows: [MCWindow], selectedWindowID: Int?) {
        self.windows = windows
        self.thumbnails = [:]
        if let selectedWindowID, let idx = windows.firstIndex(where: { $0.id == selectedWindowID }) {
            selectedIndex = idx
        } else {
            selectedIndex = 0
        }
    }

    func setThumbnail(_ image: NSImage, forWindowID id: Int) {
        thumbnails[id] = image
    }

    func next() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
    }

    func previous() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
    }

    var currentWindow: MCWindow? {
        guard windows.indices.contains(selectedIndex) else { return nil }
        return windows[selectedIndex]
    }
}
