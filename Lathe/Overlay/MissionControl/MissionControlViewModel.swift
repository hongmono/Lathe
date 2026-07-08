import AppKit
import Combine

@MainActor
final class MissionControlViewModel: ObservableObject {
    @Published private(set) var stacks: [MCAppStack] = []
    @Published private(set) var selectedStackIndex: Int = 0
    @Published private(set) var thumbnails: [Int: NSImage] = [:]

    func set(stacks: [MCAppStack], selectedWindowID: Int?) {
        self.stacks = stacks
        self.thumbnails = [:]
        if let selectedWindowID,
           let idx = stacks.firstIndex(where: { $0.windows.contains { $0.id == selectedWindowID } }) {
            selectedStackIndex = idx
        } else {
            selectedStackIndex = 0
        }
    }

    func setThumbnail(_ image: NSImage, forWindowID id: Int) {
        thumbnails[id] = image
    }

    /// ⌘+Tab: 앱(스택) 사이 이동.
    func next() {
        guard !stacks.isEmpty else { return }
        selectedStackIndex = (selectedStackIndex + 1) % stacks.count
    }

    func previous() {
        guard !stacks.isEmpty else { return }
        selectedStackIndex = (selectedStackIndex - 1 + stacks.count) % stacks.count
    }

    /// ⌘+`: 선택된 스택 안에서 창(맨 앞 카드) 순환.
    func cycleWindow() { cycle(by: 1) }
    func cycleWindowPrevious() { cycle(by: -1) }

    private func cycle(by delta: Int) {
        guard stacks.indices.contains(selectedStackIndex) else { return }
        let count = stacks[selectedStackIndex].windows.count
        guard count > 1 else { return }
        stacks[selectedStackIndex].frontIndex =
            (stacks[selectedStackIndex].frontIndex + delta + count) % count
    }

    var currentStack: MCAppStack? {
        guard stacks.indices.contains(selectedStackIndex) else { return nil }
        return stacks[selectedStackIndex]
    }

    var currentWindow: MCWindow? { currentStack?.frontWindow }
}
