import Foundation

struct WindowOrderTracker {
    private var orderByProcessIdentifier: [pid_t: [Int]] = [:]

    mutating func touch(windowID: Int, processIdentifier: pid_t) {
        var order = orderByProcessIdentifier[processIdentifier] ?? []
        order.removeAll { $0 == windowID }
        order.insert(windowID, at: 0)
        orderByProcessIdentifier[processIdentifier] = order
    }

    mutating func reconcile(processIdentifier: pid_t, liveWindowIDs: [Int]) {
        let liveSet = Set(liveWindowIDs)
        var order = orderByProcessIdentifier[processIdentifier] ?? []
        order.removeAll { !liveSet.contains($0) }
        let known = Set(order)
        for windowID in liveWindowIDs where !known.contains(windowID) {
            order.append(windowID)
        }
        orderByProcessIdentifier[processIdentifier] = order
    }

    func orderedEntries(_ entries: [WindowEntry], processIdentifier: pid_t) -> [WindowEntry] {
        let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let mru = orderByProcessIdentifier[processIdentifier] ?? []
        var result: [WindowEntry] = []
        var seen = Set<Int>()

        for windowID in mru {
            guard let entry = byID[windowID], seen.insert(windowID).inserted else { continue }
            result.append(entry)
        }
        for entry in entries where seen.insert(entry.id).inserted {
            result.append(entry)
        }
        return result
    }

    func preferredIndex(for entries: [WindowEntry], processIdentifier: pid_t) -> Int {
        guard !entries.isEmpty else { return 0 }
        let ordered = orderedEntries(entries, processIdentifier: processIdentifier)
        guard let firstID = ordered.first?.id else { return 0 }
        return entries.firstIndex(where: { $0.id == firstID }) ?? 0
    }
}
