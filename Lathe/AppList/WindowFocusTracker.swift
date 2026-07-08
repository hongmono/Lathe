import AppKit
import Foundation

@MainActor
final class WindowFocusTracker {
    private let windowListProvider: any WindowListing
    private var orderTracker: WindowOrderTracker
    private var observers: [NSObjectProtocol] = []

    init(windowListProvider: any WindowListing = WindowListProvider(),
         orderTracker: WindowOrderTracker = WindowOrderTracker()) {
        self.windowListProvider = windowListProvider
        self.orderTracker = orderTracker
        registerObservers()
    }

    var tracker: WindowOrderTracker {
        orderTracker
    }

    func replaceTracker(_ tracker: WindowOrderTracker) {
        orderTracker = tracker
    }

    func recordFocusedWindow(forProcessIdentifier pid: pid_t) {
        guard let windowID = WindowListProvider.focusedWindowID(forProcessIdentifier: pid) else { return }
        orderTracker.touch(windowID: windowID, processIdentifier: pid)
    }

    func windows(forProcessIdentifier pid: pid_t) -> [WindowEntry] {
        let live = windowListProvider.windows(forProcessIdentifier: pid)
        let liveIDs = live.map(\.id)
        orderTracker.reconcile(processIdentifier: pid, liveWindowIDs: liveIDs)
        return orderTracker.orderedEntries(live, processIdentifier: pid)
    }

    func preferredIndex(for entries: [WindowEntry], processIdentifier: pid_t) -> Int {
        orderTracker.preferredIndex(for: entries, processIdentifier: processIdentifier)
    }

    func touchSelectedWindow(_ window: WindowEntry, processIdentifier: pid_t) {
        orderTracker.touch(windowID: window.id, processIdentifier: processIdentifier)
    }

    private func registerObservers() {
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            MainActor.assumeIsolated {
                self.recordFocusedWindow(forProcessIdentifier: app.processIdentifier)
            }
        })
    }
}
