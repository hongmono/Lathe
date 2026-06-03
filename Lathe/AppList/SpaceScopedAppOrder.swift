import Foundation

struct SpaceScopedAppOrder {
    private struct SpaceMemory {
        var processIdentifiers: Set<pid_t>
        var order: [pid_t]
    }

    private var globalOrder: [pid_t] = []
    private var spaceMemories: [SpaceMemory] = []

    mutating func reconcileLiveProcessIdentifiers(_ liveProcessIdentifiers: [pid_t]) {
        let liveSet = Set(liveProcessIdentifiers)
        var known = Set(globalOrder)

        for pid in liveProcessIdentifiers where known.insert(pid).inserted {
            globalOrder.append(pid)
        }

        globalOrder.removeAll { !liveSet.contains($0) }

        for index in spaceMemories.indices {
            spaceMemories[index].processIdentifiers.formIntersection(liveSet)
            spaceMemories[index].order.removeAll { !liveSet.contains($0) }
        }
        spaceMemories.removeAll { $0.processIdentifiers.isEmpty || $0.order.isEmpty }
    }

    mutating func touch(pid: pid_t, currentSpaceProcessIdentifiers: Set<pid_t>) {
        Self.moveToFront(pid, in: &globalOrder)

        guard currentSpaceProcessIdentifiers.contains(pid) else { return }
        let index = memoryIndex(for: currentSpaceProcessIdentifiers) ?? createMemory(for: currentSpaceProcessIdentifiers)
        spaceMemories[index].processIdentifiers = currentSpaceProcessIdentifiers
        seedMissingCurrentSpaceProcessIdentifiers(in: index)
        Self.moveToFront(pid, in: &spaceMemories[index].order)
    }

    mutating func orderedProcessIdentifiers(currentSpaceProcessIdentifiers: Set<pid_t>) -> [pid_t] {
        guard !currentSpaceProcessIdentifiers.isEmpty else { return globalOrder }

        let index = memoryIndex(for: currentSpaceProcessIdentifiers) ?? createMemory(for: currentSpaceProcessIdentifiers)
        spaceMemories[index].processIdentifiers = currentSpaceProcessIdentifiers
        seedMissingCurrentSpaceProcessIdentifiers(in: index)

        let currentSpaceOrder = spaceMemories[index].order.filter { currentSpaceProcessIdentifiers.contains($0) }
        let otherOrder = globalOrder.filter { !currentSpaceProcessIdentifiers.contains($0) }
        return currentSpaceOrder + otherOrder
    }

    private mutating func createMemory(for processIdentifiers: Set<pid_t>) -> Int {
        let seededOrder = globalOrder.filter { processIdentifiers.contains($0) }
        spaceMemories.append(SpaceMemory(processIdentifiers: processIdentifiers, order: seededOrder))
        return spaceMemories.index(before: spaceMemories.endIndex)
    }

    private mutating func seedMissingCurrentSpaceProcessIdentifiers(in index: Int) {
        let currentProcessIdentifiers = spaceMemories[index].processIdentifiers
        let known = Set(spaceMemories[index].order)
        for pid in globalOrder where currentProcessIdentifiers.contains(pid) && !known.contains(pid) {
            spaceMemories[index].order.append(pid)
        }
        spaceMemories[index].order.removeAll { !currentProcessIdentifiers.contains($0) }
    }

    private func memoryIndex(for processIdentifiers: Set<pid_t>) -> Int? {
        if let exactMatch = spaceMemories.firstIndex(where: { $0.processIdentifiers == processIdentifiers }) {
            return exactMatch
        }

        let candidates = spaceMemories.indices.compactMap { index -> (index: Int, overlap: Int, symmetricDifference: Int)? in
            let remembered = spaceMemories[index].processIdentifiers
            let overlap = remembered.intersection(processIdentifiers).count
            guard overlap >= 2 else { return nil }
            let symmetricDifference = remembered.symmetricDifference(processIdentifiers).count
            return (index, overlap, symmetricDifference)
        }

        return candidates
            .sorted {
                if $0.overlap != $1.overlap {
                    return $0.overlap > $1.overlap
                }
                return $0.symmetricDifference < $1.symmetricDifference
            }
            .first?
            .index
    }

    private static func moveToFront(_ pid: pid_t, in order: inout [pid_t]) {
        order.removeAll { $0 == pid }
        order.insert(pid, at: 0)
    }
}
