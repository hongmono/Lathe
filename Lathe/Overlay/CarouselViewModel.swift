import Foundation
import Combine

@MainActor
final class CarouselViewModel: ObservableObject {
    @Published private(set) var apps: [AppEntry] = []
    @Published private(set) var selectedIndex: Int = 0

    func update(apps: [AppEntry], selectedIndex: Int) {
        self.apps = apps
        self.selectedIndex = clamp(selectedIndex, count: apps.count)
    }

    func replaceApps(_ newApps: [AppEntry]) {
        // 인덱스가 아니라 pid로 선택을 추적한다. 목록이 밀려도 같은 앱을 가리키도록.
        let selectedID = currentEntry?.id
        self.apps = newApps
        if let selectedID, let newIndex = newApps.firstIndex(where: { $0.id == selectedID }) {
            self.selectedIndex = newIndex
        } else {
            self.selectedIndex = clamp(selectedIndex, count: newApps.count)
        }
    }

    func next() {
        guard !apps.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % apps.count
    }

    func previous() {
        guard !apps.isEmpty else { return }
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
