import Foundation
import Combine

@MainActor
final class CarouselViewModel: ObservableObject {
    @Published private(set) var apps: [AppEntry] = []
    @Published private(set) var selectedIndex: Int = 0
    @Published private(set) var isPresentationExpanded = true
    private(set) var selectionPosition: Int = 0
    private(set) var selectionDirection: Int = 0
    /// hover 중인 앱 카드. dim(거리 기반 opacity) 제거에만 쓴다.
    @Published private(set) var hoveredAppID: pid_t?

    func setHovered(_ id: pid_t?) {
        if hoveredAppID != id { hoveredAppID = id }
    }

    func update(apps: [AppEntry], selectedIndex: Int) {
        let clampedIndex = clamp(selectedIndex, count: apps.count)
        self.selectionDirection = 0
        self.selectionPosition = clampedIndex
        self.apps = apps
        self.selectedIndex = clampedIndex
    }

    func preparePresentation(apps: [AppEntry], selectedIndex: Int, animated: Bool) {
        isPresentationExpanded = !animated
        update(apps: apps, selectedIndex: selectedIndex)
    }

    func completePresentation() {
        isPresentationExpanded = true
    }

    func replaceApps(_ newApps: [AppEntry]) {
        // 인덱스가 아니라 pid로 선택을 추적한다. 목록이 밀려도 같은 앱을 가리키도록.
        let selectedID = currentEntry?.id
        if apps.map(\.id) == newApps.map(\.id) {
            apps = newApps
            return
        }
        let newIndex: Int
        if let selectedID, let matchingIndex = newApps.firstIndex(where: { $0.id == selectedID }) {
            newIndex = matchingIndex
        } else {
            newIndex = clamp(selectedIndex, count: newApps.count)
        }
        selectionDirection = 0
        selectionPosition = newIndex
        apps = newApps
        selectedIndex = newIndex
    }

    /// 카드 클릭: 특정 인덱스를 선택한다.
    func select(_ index: Int) {
        let clampedIndex = clamp(index, count: apps.count)
        selectionDirection = 0
        selectionPosition = clampedIndex
        selectedIndex = clampedIndex
    }

    func next() {
        guard apps.count > 1 else { return }
        selectionDirection = 1
        selectionPosition += 1
        selectedIndex = (selectedIndex + 1) % apps.count
    }

    func previous() {
        guard apps.count > 1 else { return }
        selectionDirection = -1
        selectionPosition -= 1
        selectedIndex = (selectedIndex - 1 + apps.count) % apps.count
    }

    var currentEntry: AppEntry? {
        guard apps.indices.contains(selectedIndex) else { return nil }
        return apps[selectedIndex]
    }

    private func clamp(_ i: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return max(0, min(i, count - 1))
    }
}
